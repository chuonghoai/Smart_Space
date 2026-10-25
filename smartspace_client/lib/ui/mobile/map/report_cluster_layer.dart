import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/ui/components/marker_image_generator.dart';

/// Màu của lớp cluster, lấy từ theme hiện tại.
@immutable
class ReportClusterColors {
  final Color normal;
  final Color onNormal;
  final Color dangerous;
  final Color onDangerous;
  final Color stroke;

  const ReportClusterColors({
    required this.normal,
    required this.onNormal,
    required this.dangerous,
    required this.onDangerous,
    required this.stroke,
  });

  factory ReportClusterColors.fromTheme(ThemeData theme) {
    final cs = theme.colorScheme;
    return ReportClusterColors(
      normal: cs.primary,
      onNormal: cs.onPrimary,
      dangerous: cs.error,
      onDangerous: cs.onError,
      stroke: cs.surface,
    );
  }

  /// Dùng trong id ảnh marker để đổi theme thì tạo lại ảnh đúng màu.
  String get cacheKey =>
      '${normal.toARGB32().toRadixString(16)}${dangerous.toARGB32().toRadixString(16)}';

  @override
  bool operator ==(Object other) =>
      other is ReportClusterColors &&
      other.normal == normal &&
      other.onNormal == onNormal &&
      other.dangerous == dangerous &&
      other.onDangerous == onDangerous &&
      other.stroke == stroke;

  @override
  int get hashCode => Object.hash(normal, onNormal, dangerous, onDangerous, stroke);
}

/// Lớp report trên Mapbox: 1 GeoJSON source có cluster + 3 layer
/// (vòng cluster, số đếm, marker ảnh của điểm lẻ).
///
/// Ảnh marker:
/// - 2 marker mặc định (nguy hiểm / thông thường) được đăng ký trước khi cài layer,
///   nên điểm lẻ luôn hiển thị ngay (icon dùng `coalesce` ảnh thật → ảnh mặc định).
/// - Ảnh thật chỉ tải cho điểm lẻ đang hiện trên màn hình ([loadVisibleImages]),
///   sau đó nạp lại data để Mapbox dựng lại tile với ảnh mới.
class ReportClusterLayer {
  static const String sourceId = 'smartspace-reports';
  static const String clusterLayerId = 'smartspace-reports-clusters';
  static const String countLayerId = 'smartspace-reports-cluster-count';
  static const String pointLayerId = 'smartspace-reports-points';

  static const double clusterRadius = 50;
  static const double clusterMaxZoom = 16;

  static const String _imagePrefix = 'smartspace-report-';
  static const String _fallbackPrefix = 'smartspace-report-fallback-';

  /// Giới hạn mỗi lượt tải ảnh thật để không quá tải mạng/bộ nhớ.
  static const int _maxImagesPerPass = 60;
  static const int _imageConcurrency = 4;

  final MapboxMap _map;
  final MarkerImageGenerator _markerGenerator;
  final double _pixelRatio;

  ReportClusterColors _colors;
  List<ReportModel> _reports = const [];
  final Map<String, ReportModel> _reportByImageKey = {};
  final Set<String> _registeredImages = {};
  final Set<String> _pendingImages = {};
  bool _installed = false;
  bool _loadingVisibleImages = false;

  ReportClusterLayer({
    required MapboxMap map,
    required MarkerImageGenerator markerGenerator,
    required ReportClusterColors colors,
    required double pixelRatio,
  })  : _map = map,
        _markerGenerator = markerGenerator,
        _colors = colors,
        _pixelRatio = pixelRatio;

  /// Thêm source + layer vào style. Gọi lại mỗi khi style load xong
  /// (style reload sẽ xoá toàn bộ source/layer/ảnh đã thêm).
  Future<void> install(List<ReportModel> reports) async {
    _installed = false;
    _registeredImages.clear();
    _pendingImages.clear();
    _reports = reports;
    _indexReports(reports);

    await _registerFallbackImages();

    final style = _map.style;
    if (!await style.styleSourceExists(sourceId)) {
      await style.addSource(GeoJsonSource(
        id: sourceId,
        data: _featureCollection(_reports),
        cluster: true,
        clusterRadius: clusterRadius,
        clusterMaxZoom: clusterMaxZoom,
        clusterProperties: {
          'dangerCount': [
            '+',
            ['case', ['get', 'isDangerous'], 1, 0],
          ],
        },
      ));
    }
    if (!await style.styleLayerExists(clusterLayerId)) {
      await style.addLayer(_clusterLayer());
    }
    if (!await style.styleLayerExists(countLayerId)) {
      await style.addLayer(_countLayer());
    }
    if (!await style.styleLayerExists(pointLayerId)) {
      await style.addLayer(_pointLayer());
    }
    _installed = true;

    // Dữ liệu có thể đã đổi trong lúc đang cài layer → đẩy bản mới nhất
    if (!identical(_reports, reports)) await setReports(_reports);
  }

  Future<void> setReports(List<ReportModel> reports) async {
    _reports = reports;
    _indexReports(reports);
    if (!_installed) return;
    await _map.style.setStyleSourceProperty(sourceId, 'data', _featureCollection(reports));
  }

  /// Đổi màu theo theme. Ảnh marker mang màu viền nên id ảnh đổi theo → tạo lại.
  Future<void> updateColors(ReportClusterColors colors, List<ReportModel> reports) async {
    if (colors == _colors) return;
    _colors = colors;
    if (!_installed) return;
    await _registerFallbackImages();
    await _map.style.updateLayer(_clusterLayer());
    await _map.style.updateLayer(_countLayer());
    await setReports(reports);
  }

  /// Tải ảnh thật cho các điểm lẻ đang hiện trong khung [width] x [height] (logical px).
  /// Gọi khi bản đồ idle; không làm gì nếu mọi ảnh đã có.
  Future<void> loadVisibleImages(double width, double height) async {
    if (!_installed || _loadingVisibleImages) return;
    _loadingVisibleImages = true;
    try {
      final hits = await _map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(x: 0, y: 0),
            max: ScreenCoordinate(x: width, y: height),
          ),
        ),
        RenderedQueryOptions(layerIds: [pointLayerId]),
      );

      final missing = <String>{
        for (final hit in hits)
          if ((hit?.queriedFeature.feature['properties'] as Map?)?['imageKey']
              case final String key)
            if (!_registeredImages.contains(key) &&
                !_pendingImages.contains(key) &&
                _reportByImageKey.containsKey(key))
              key,
      }.take(_maxImagesPerPass).toList();
      if (missing.isEmpty) return;

      var added = false;
      for (var i = 0; i < missing.length; i += _imageConcurrency) {
        final batch = missing.skip(i).take(_imageConcurrency);
        final results = await Future.wait(
          batch.map((key) => _registerPhotoImage(key, _reportByImageKey[key]!)),
        );
        added = added || results.contains(true);
      }

      // Nạp lại data để tile được dựng lại, lúc này ảnh thật đã có trong style
      if (added) await setReports(_reports);
    } catch (e) {
      debugPrint('[ReportClusterLayer] Failed to load visible marker images — $e');
    } finally {
      _loadingVisibleImages = false;
    }
  }

  String imageKeyFor(ReportModel report) =>
      '$_imagePrefix${report.id}-${_typeSuffix(report)}-${_colors.cacheKey}';

  String fallbackKeyFor(ReportModel report) =>
      '$_fallbackPrefix${_typeSuffix(report)}-${_colors.cacheKey}';

  static String _typeSuffix(ReportModel report) => report.isDangerous ? 'd' : 'n';

  String _featureCollection(List<ReportModel> reports) =>
      toFeatureCollection(reports, imageKeyFor, fallbackKeyFor);

  void _indexReports(List<ReportModel> reports) {
    _reportByImageKey
      ..clear()
      ..addEntries(reports.map((r) => MapEntry(imageKeyFor(r), r)));
  }

  /// Marker không có ảnh (không cần mạng) cho từng loại, theo màu hiện tại.
  Future<void> _registerFallbackImages() async {
    for (final isDangerous in [true, false]) {
      final suffix = isDangerous ? 'd' : 'n';
      final key = '$_fallbackPrefix$suffix-${_colors.cacheKey}';
      if (_registeredImages.contains(key)) continue;
      final bytes = await _markerGenerator.generateMarkerImage(
        imageUrl: '',
        borderColor: isDangerous ? _colors.dangerous : _colors.normal,
        cacheKey: 'fallback-$suffix',
        isDangerous: isDangerous,
      );
      if (await _addImage(key, bytes)) _registeredImages.add(key);
    }
  }

  /// Trả về true nếu đã thêm ảnh mới vào style.
  Future<bool> _registerPhotoImage(String imageId, ReportModel report) async {
    if (!_pendingImages.add(imageId)) return false;
    try {
      final bytes = await _markerGenerator.generateMarkerImage(
        imageUrl: report.imageUrl,
        borderColor: report.isDangerous ? _colors.dangerous : _colors.normal,
        cacheKey: report.id,
        isDangerous: report.isDangerous,
      );
      final added = await _addImage(imageId, bytes);
      if (added) _registeredImages.add(imageId);
      return added;
    } finally {
      _pendingImages.remove(imageId);
    }
  }

  Future<bool> _addImage(String imageId, Uint8List pngBytes) async {
    try {
      await _map.style.addStyleImage(
        imageId,
        _pixelRatio,
        MbxImage(
          width: MarkerImageGenerator.markerWidth,
          height: MarkerImageGenerator.markerHeight,
          data: pngBytes,
        ),
        false,
        [],
        [],
        null,
      );
      return true;
    } catch (e) {
      debugPrint('[ReportClusterLayer] Failed to add marker image $imageId — $e');
      return false;
    }
  }

  CircleLayer _clusterLayer() {
    return CircleLayer(
      id: clusterLayerId,
      sourceId: sourceId,
      filter: ['has', 'point_count'],
      circleColorExpression: [
        'case',
        ['>', ['get', 'dangerCount'], 0],
        _rgba(_colors.dangerous),
        _rgba(_colors.normal),
      ],
      // < 10 điểm: 18px, 10–49: 22px, >= 50: 28px
      circleRadiusExpression: ['step', ['get', 'point_count'], 18, 10, 22, 50, 28],
      circleStrokeColor: _colors.stroke.toARGB32(),
      circleStrokeWidth: 3,
    );
  }

  SymbolLayer _countLayer() {
    return SymbolLayer(
      id: countLayerId,
      sourceId: sourceId,
      filter: ['has', 'point_count'],
      textFieldExpression: ['get', 'point_count_abbreviated'],
      textFont: ['DIN Pro Medium', 'Arial Unicode MS Regular'],
      textSize: 13,
      textColorExpression: [
        'case',
        ['>', ['get', 'dangerCount'], 0],
        _rgba(_colors.onDangerous),
        _rgba(_colors.onNormal),
      ],
      textAllowOverlap: true,
      textIgnorePlacement: true,
    );
  }

  SymbolLayer _pointLayer() {
    return SymbolLayer(
      id: pointLayerId,
      sourceId: sourceId,
      filter: ['!', ['has', 'point_count']],
      // Ảnh thật nếu đã tải, không thì marker mặc định → điểm lẻ không bao giờ bị ẩn
      iconImageExpression: [
        'coalesce',
        ['image', ['get', 'imageKey']],
        ['image', ['get', 'fallbackKey']],
      ],
      iconSizeExpression: ['case', ['get', 'isDangerous'], 0.55, 0.45],
      iconAnchor: IconAnchor.BOTTOM,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      // Sort key lớn hơn được vẽ sau → report nguy hiểm nằm trên
      symbolSortKeyExpression: ['case', ['get', 'isDangerous'], 1, 0],
    );
  }

  /// Mapbox expression cần màu dạng chuỗi CSS.
  static String _rgba(Color color) {
    final argb = color.toARGB32();
    final a = ((argb >> 24) & 0xFF) / 255;
    return 'rgba(${(argb >> 16) & 0xFF}, ${(argb >> 8) & 0xFF}, ${argb & 0xFF}, ${a.toStringAsFixed(3)})';
  }

  /// Chuyển report thành GeoJSON FeatureCollection. Bỏ report không có toạ độ (0,0).
  static String toFeatureCollection(
    List<ReportModel> reports,
    String Function(ReportModel report) imageKey,
    String Function(ReportModel report) fallbackKey,
  ) {
    final features = [
      for (final report in reports)
        if (report.latitude != 0 || report.longitude != 0)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [report.longitude, report.latitude],
            },
            'properties': {
              'id': report.id,
              'isDangerous': report.isDangerous,
              'imageKey': imageKey(report),
              'fallbackKey': fallbackKey(report),
            },
          },
    ];
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
