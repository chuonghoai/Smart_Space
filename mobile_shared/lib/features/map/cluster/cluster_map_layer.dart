import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';

import 'cluster_layer_colors.dart';

export 'cluster_layer_colors.dart';

/// Một điểm trên bản đồ cluster, không phụ thuộc model của từng app.
@immutable
class ClusterMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;

  /// Được đếm vào `alertCount` → cluster chứa điểm này được tô màu cảnh báo.
  final bool isAlert;

  /// Icon to hơn và vẽ đè lên các điểm khác.
  final bool isEmphasized;

  /// Phân biệt biến thể ảnh marker (vd. `d`/`n`, hoặc trạng thái report).
  final String styleKey;

  const ClusterMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.isAlert,
    required this.isEmphasized,
    required this.styleKey,
  });
}

/// Tạo PNG cho marker. `withPhoto = false` → marker mặc định (không cần mạng).
typedef ClusterMarkerImageBuilder = Future<Uint8List> Function(
  ClusterMarker marker, {
  required bool withPhoto,
});

/// Kết quả xử lý một lần bấm lên bản đồ.
sealed class ClusterTapResult {
  const ClusterTapResult();
}

/// Bấm trúng một điểm lẻ.
class ClusterPointTapped extends ClusterTapResult {
  final String id;
  const ClusterPointTapped(this.id);
}

/// Bấm trúng cluster còn tách được → camera đã zoom vào.
class ClusterZoomedIn extends ClusterTapResult {
  const ClusterZoomedIn();
}

/// Bấm trúng cluster không tách được nữa (trùng/sát toạ độ) → app mở danh sách.
class ClusterLeavesTapped extends ClusterTapResult {
  final Set<String> ids;
  const ClusterLeavesTapped(this.ids);
}

/// Lớp cluster trên Mapbox native: 1 GeoJSON source có cluster + 3 layer
/// (vòng cluster, số đếm, marker ảnh của điểm lẻ). Dùng chung Client/Admin.
///
/// Ảnh marker:
/// - Marker mặc định cho từng [ClusterMarker.styleKey] được đăng ký trước khi đẩy data,
///   icon dùng `coalesce` (ảnh thật → mặc định) nên điểm lẻ luôn hiển thị.
/// - Ảnh thật chỉ tải cho điểm lẻ đang hiện trên màn hình ([loadVisibleImages]),
///   sau đó nạp lại data để Mapbox dựng lại tile với ảnh mới.
class ClusterMapLayer {
  static const double clusterRadius = 50;
  static const double clusterMaxZoom = 16;

  /// Vùng chạm quanh ngón tay (logical px) để bấm marker nhỏ không bị trượt.
  static const double tapTolerance = 10;

  static const int _maxImagesPerPass = 60;
  static const int _imageConcurrency = 4;

  final MapboxMap _map;
  final ClusterMarkerImageBuilder _imageBuilder;
  final double _pixelRatio;
  final int _imageWidth;
  final int _imageHeight;

  final String sourceId;
  final String clusterLayerId;
  final String countLayerId;
  final String pointLayerId;

  ClusterLayerColors _colors;
  List<ClusterMarker> _markers = const [];
  final Map<String, ClusterMarker> _markerByImageKey = {};
  final Set<String> _registeredImages = {};
  final Set<String> _pendingImages = {};
  bool _installed = false;
  bool _loadingVisibleImages = false;

  ClusterMapLayer({
    required MapboxMap map,
    required ClusterMarkerImageBuilder imageBuilder,
    required ClusterLayerColors colors,
    required double pixelRatio,
    required int imageWidth,
    required int imageHeight,
    String idPrefix = 'smartspace-reports',
  })  : _map = map,
        _imageBuilder = imageBuilder,
        _colors = colors,
        _pixelRatio = pixelRatio,
        _imageWidth = imageWidth,
        _imageHeight = imageHeight,
        sourceId = idPrefix,
        clusterLayerId = '$idPrefix-clusters',
        countLayerId = '$idPrefix-cluster-count',
        pointLayerId = '$idPrefix-points';

  String get _imagePrefix => '$sourceId-img-';
  String get _fallbackPrefix => '$sourceId-fallback-';

  /// Thêm source + layer vào style. Gọi lại mỗi khi style load xong
  /// (style reload sẽ xoá toàn bộ source/layer/ảnh đã thêm).
  Future<void> install(List<ClusterMarker> markers) async {
    _installed = false;
    _registeredImages.clear();
    _pendingImages.clear();
    _markers = markers;
    _indexMarkers(markers);

    await _registerFallbackImages(markers);

    final style = _map.style;
    if (!await style.styleSourceExists(sourceId)) {
      await style.addSource(GeoJsonSource(
        id: sourceId,
        data: _featureCollection(_markers),
        cluster: true,
        clusterRadius: clusterRadius,
        clusterMaxZoom: clusterMaxZoom,
        clusterProperties: {
          'alertCount': [
            '+',
            ['case', ['get', 'isAlert'], 1, 0],
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
    if (!identical(_markers, markers)) await setMarkers(_markers);
  }

  Future<void> setMarkers(List<ClusterMarker> markers) async {
    _markers = markers;
    _indexMarkers(markers);
    if (!_installed) return;
    await _registerFallbackImages(markers);
    await _map.style.setStyleSourceProperty(sourceId, 'data', _featureCollection(markers));
  }

  /// Đổi màu theo theme. Ảnh marker mang màu nên id ảnh đổi theo → tạo lại.
  Future<void> updateColors(ClusterLayerColors colors) async {
    if (colors == _colors) return;
    _colors = colors;
    if (!_installed) return;
    await _map.style.updateLayer(_clusterLayer());
    await _map.style.updateLayer(_countLayer());
    await setMarkers(_markers);
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
          if (_propertiesOf(hit?.queriedFeature.feature)['imageKey'] case final String key)
            if (!_registeredImages.contains(key) &&
                !_pendingImages.contains(key) &&
                _markerByImageKey.containsKey(key))
              key,
      }.take(_maxImagesPerPass).toList();
      if (missing.isEmpty) return;

      var added = false;
      for (var i = 0; i < missing.length; i += _imageConcurrency) {
        final batch = missing.skip(i).take(_imageConcurrency);
        final results = await Future.wait(
          batch.map((key) => _registerPhotoImage(key, _markerByImageKey[key]!)),
        );
        added = added || results.contains(true);
      }

      // Nạp lại data để tile được dựng lại, lúc này ảnh thật đã có trong style
      if (added) await setMarkers(_markers);
    } catch (e) {
      debugPrint('[ClusterMapLayer] Failed to load visible marker images — $e');
    } finally {
      _loadingVisibleImages = false;
    }
  }

  /// Xử lý tap: điểm lẻ → [ClusterPointTapped]; cluster tách được → zoom vào;
  /// cluster không tách được nữa → [ClusterLeavesTapped]. Không trúng gì → null.
  Future<ClusterTapResult?> handleTap(
    MapContentGestureContext gestureContext, {
    required bool reduceMotion,
  }) async {
    final touch = gestureContext.touchPosition;
    final List<QueriedRenderedFeature?> hits;
    try {
      hits = await _map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(x: touch.x - tapTolerance, y: touch.y - tapTolerance),
            max: ScreenCoordinate(x: touch.x + tapTolerance, y: touch.y + tapTolerance),
          ),
        ),
        RenderedQueryOptions(layerIds: [clusterLayerId, pointLayerId]),
      );
    } catch (e) {
      debugPrint('[ClusterMapLayer] Tap query failed — $e');
      return null;
    }

    final features = [
      for (final hit in hits)
        if (hit != null) hit.queriedFeature.feature,
    ];
    if (features.isEmpty) return null;

    // Ưu tiên cluster nếu vùng chạm trúng cả cluster lẫn điểm lẻ
    final cluster = features.where(isClusterFeature).firstOrNull;
    if (cluster == null) {
      final id = _propertiesOf(features.first)['id'];
      return id is String ? ClusterPointTapped(id) : null;
    }
    return _handleClusterTap(cluster, gestureContext, reduceMotion: reduceMotion);
  }

  Future<ClusterTapResult> _handleClusterTap(
    Map<String?, Object?> cluster,
    MapContentGestureContext gestureContext, {
    required bool reduceMotion,
  }) async {
    final properties = _propertiesOf(cluster);
    final center = pointOf(cluster['geometry']) ?? gestureContext.point;

    try {
      final expansion = await _map.getGeoJsonClusterExpansionZoom(sourceId, cluster);
      final expansionZoom = double.tryParse(expansion.value ?? '');

      // Tầng 1: zoom vào được → bay tới mức zoom mà cluster tách ra
      if (expansionZoom != null && expansionZoom <= clusterMaxZoom) {
        await _easeTo(center, expansionZoom, reduceMotion: reduceMotion);
        return const ClusterZoomedIn();
      }

      // Tầng 2: không tách được nữa → trả về các id trong cluster
      final pointCount = (properties['point_count'] as num?)?.toInt() ?? 0;
      final leaves = await _map.getGeoJsonClusterLeaves(sourceId, cluster, pointCount, 0);
      return ClusterLeavesTapped({
        for (final leaf in leaves.featureCollection ?? const [])
          if (_propertiesOf(leaf)['id'] case final String id) id,
      });
    } catch (e) {
      // Không đọc được thông tin cluster → vẫn phản hồi bằng cách zoom vào thêm
      debugPrint('[ClusterMapLayer] Cluster tap failed — $e');
      final camera = await _map.getCameraState();
      await _easeTo(
        center,
        (camera.zoom + 2).clamp(0, clusterMaxZoom + 1).toDouble(),
        reduceMotion: reduceMotion,
      );
      return const ClusterZoomedIn();
    }
  }

  Future<void> _easeTo(Point center, double zoom, {required bool reduceMotion}) {
    return _map.easeTo(
      CameraOptions(center: center, zoom: zoom),
      MapAnimationOptions(duration: reduceMotion ? 0 : 500),
    );
  }

  /// Khung nhìn hiện tại của camera; null nếu không xác định (vd. vắt qua kinh tuyến 180°).
  static Future<MapBounds?> readViewport(MapboxMap map) async {
    final camera = await map.getCameraState();
    final bounds = await map.coordinateBoundsForCamera(camera.toCameraOptions());
    if (bounds.infiniteBounds) return null;

    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;
    if (sw.lng > ne.lng) return null;

    return MapBounds(
      minLat: sw.lat.toDouble(),
      maxLat: ne.lat.toDouble(),
      minLng: sw.lng.toDouble(),
      maxLng: ne.lng.toDouble(),
    );
  }

  static bool isClusterFeature(Map<String?, Object?> feature) =>
      _propertiesOf(feature).containsKey('point_count');

  static Map<Object?, Object?> _propertiesOf(Map<Object?, Object?>? feature) =>
      (feature?['properties'] as Map?) ?? const {};

  static Point? pointOf(Object? geometry) {
    if (geometry is! Map) return null;
    final coordinates = geometry['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final lng = coordinates[0];
      final lat = coordinates[1];
      if (lng is num && lat is num) {
        return Point(coordinates: Position(lng, lat));
      }
    }
    return null;
  }

  String imageKeyFor(ClusterMarker marker) =>
      '$_imagePrefix${marker.id}-${marker.styleKey}-${_colors.cacheKey}';

  String fallbackKeyFor(ClusterMarker marker) =>
      '$_fallbackPrefix${marker.styleKey}-${_colors.cacheKey}';

  String _featureCollection(List<ClusterMarker> markers) =>
      toFeatureCollection(markers, imageKeyFor, fallbackKeyFor);

  void _indexMarkers(List<ClusterMarker> markers) {
    _markerByImageKey
      ..clear()
      ..addEntries(markers.map((m) => MapEntry(imageKeyFor(m), m)));
  }

  /// Marker mặc định (không cần mạng) cho mỗi styleKey chưa có ảnh.
  Future<void> _registerFallbackImages(List<ClusterMarker> markers) async {
    final byKey = <String, ClusterMarker>{
      for (final marker in markers) fallbackKeyFor(marker): marker,
    };
    for (final entry in byKey.entries) {
      if (_registeredImages.contains(entry.key)) continue;
      try {
        final bytes = await _imageBuilder(entry.value, withPhoto: false);
        if (await _addImage(entry.key, bytes)) _registeredImages.add(entry.key);
      } catch (e) {
        debugPrint('[ClusterMapLayer] Failed to build fallback marker ${entry.key} — $e');
      }
    }
  }

  /// Trả về true nếu đã thêm ảnh mới vào style.
  Future<bool> _registerPhotoImage(String imageId, ClusterMarker marker) async {
    if (!_pendingImages.add(imageId)) return false;
    try {
      final bytes = await _imageBuilder(marker, withPhoto: true);
      final added = await _addImage(imageId, bytes);
      if (added) _registeredImages.add(imageId);
      return added;
    } catch (e) {
      debugPrint('[ClusterMapLayer] Failed to build marker $imageId — $e');
      return false;
    } finally {
      _pendingImages.remove(imageId);
    }
  }

  Future<bool> _addImage(String imageId, Uint8List pngBytes) async {
    try {
      await _map.style.addStyleImage(
        imageId,
        _pixelRatio,
        MbxImage(width: _imageWidth, height: _imageHeight, data: pngBytes),
        false,
        [],
        [],
        null,
      );
      return true;
    } catch (e) {
      debugPrint('[ClusterMapLayer] Failed to add marker image $imageId — $e');
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
        ['>', ['get', 'alertCount'], 0],
        ClusterLayerColors.toRgba(_colors.alert),
        ClusterLayerColors.toRgba(_colors.normal),
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
        ['>', ['get', 'alertCount'], 0],
        ClusterLayerColors.toRgba(_colors.onAlert),
        ClusterLayerColors.toRgba(_colors.onNormal),
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
      iconSizeExpression: ['case', ['get', 'isEmphasized'], 0.55, 0.45],
      iconAnchor: IconAnchor.BOTTOM,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      // Sort key lớn hơn được vẽ sau → điểm nhấn mạnh nằm trên
      symbolSortKeyExpression: ['case', ['get', 'isEmphasized'], 1, 0],
    );
  }

  /// Chuyển marker thành GeoJSON FeatureCollection. Bỏ điểm không có toạ độ (0,0).
  static String toFeatureCollection(
    List<ClusterMarker> markers,
    String Function(ClusterMarker marker) imageKey,
    String Function(ClusterMarker marker) fallbackKey,
  ) {
    final features = [
      for (final marker in markers)
        if (marker.latitude != 0 || marker.longitude != 0)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [marker.longitude, marker.latitude],
            },
            'properties': {
              'id': marker.id,
              'isAlert': marker.isAlert,
              'isEmphasized': marker.isEmphasized,
              'imageKey': imageKey(marker),
              'fallbackKey': fallbackKey(marker),
            },
          },
    ];
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
