import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/features/reports/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/map_reports_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/components/map_cluster_sheet.dart';
import 'package:smartspace_client/ui/components/map_controls.dart';
import 'package:smartspace_client/ui/components/marker_image_generator.dart';
import 'package:smartspace_client/ui/components/report_info_sheet.dart';
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';
import 'package:smartspace_client/ui/mobile/map/report_cluster_layer.dart';

/// Mobile Map Screen — report theo khung nhìn, gom cụm (cluster).
///
/// Bấm cluster: zoom tới mức cluster tách ra; nếu không tách được nữa
/// (trùng/sát toạ độ) thì mở danh sách report trong cluster.
class MobileMapScreen extends ConsumerStatefulWidget {
  const MobileMapScreen({super.key});

  @override
  ConsumerState<MobileMapScreen> createState() => _MobileMapScreenState();
}

class _MobileMapScreenState extends ConsumerState<MobileMapScreen> {
  MapboxMap? _mapboxMap;
  ReportClusterLayer? _clusterLayer;
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  ReportClusterColors? _colors;
  double _pixelRatio = 1;

  /// Report đang vẽ trên bản đồ (đã áp filter).
  List<ReportModel> _visibleReports = const [];

  // HCM city center
  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final colors = ReportClusterColors.fromTheme(Theme.of(context));
    if (colors != _colors) {
      _colors = colors;
      _clusterLayer?.updateColors(colors, _visibleReports);
    }
  }

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _clusterLayer = ReportClusterLayer(
      map: mapboxMap,
      markerGenerator: _markerGenerator,
      colors: _colors ?? ReportClusterColors.fromTheme(Theme.of(context)),
      pixelRatio: _pixelRatio,
    );

    // Bắt tap ở mức bản đồ rồi tự query feature: không phụ thuộc việc layer
    // cluster đã tồn tại lúc đăng ký, và lấy được feature gốc từ source
    // (đúng dạng mà getGeoJsonCluster* yêu cầu).
    mapboxMap.addInteraction(
      TapInteraction.onMap(_onMapTap, stopPropagation: false),
    );

    // Set 2D top-down camera (radar view)
    await mapboxMap.setCamera(
      CameraOptions(
        center: _defaultCenter,
        zoom: 12.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
    );

    await mapboxMap.style.setStyleImportConfigProperty(
      'basemap',
      'showRoadsAndTransit',
      true,
    );
  }

  /// Style load xong (kể cả reload) → thêm lại source/layer rồi tải report.
  void _onStyleLoaded(StyleLoadedEventData _) async {
    await _clusterLayer?.install(_visibleReports);
    _emitViewport();
  }

  void _onMapIdle(MapIdleEventData _) {
    _emitViewport();
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    _clusterLayer?.loadVisibleImages(size.width, size.height);
  }

  Future<void> _emitViewport() async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    try {
      final camera = await map.getCameraState();
      final bounds = await map.coordinateBoundsForCamera(camera.toCameraOptions());
      if (!mounted || bounds.infiniteBounds) return;

      final sw = bounds.southwest.coordinates;
      final ne = bounds.northeast.coordinates;
      // Khung vắt qua kinh tuyến 180° không xảy ra trong phạm vi app → bỏ qua
      if (sw.lng > ne.lng) return;

      ref.read(mapControllerProvider.notifier).onViewportChanged(
            MapBounds(
              minLat: sw.lat.toDouble(),
              maxLat: ne.lat.toDouble(),
              minLng: sw.lng.toDouble(),
              maxLng: ne.lng.toDouble(),
            ),
          );
    } catch (e) {
      debugPrint('[MapScreen] Failed to read viewport — $e');
    }
  }

  void _syncReports() {
    final filtered = ref
        .read(mapControllerProvider)
        .getFilteredReports(ref.read(mapReportsProvider).reports);
    _visibleReports = filtered;
    _clusterLayer?.setReports(filtered);
  }

  /// Vùng chạm quanh ngón tay (logical px) để bấm marker nhỏ không bị trượt.
  static const double _tapTolerance = 10;

  Future<void> _onMapTap(MapContentGestureContext gestureContext) async {
    final map = _mapboxMap;
    if (map == null) return;

    final touch = gestureContext.touchPosition;
    try {
      final hits = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(x: touch.x - _tapTolerance, y: touch.y - _tapTolerance),
            max: ScreenCoordinate(x: touch.x + _tapTolerance, y: touch.y + _tapTolerance),
          ),
        ),
        RenderedQueryOptions(layerIds: [
          ReportClusterLayer.clusterLayerId,
          ReportClusterLayer.pointLayerId,
        ]),
      );

      final features = [
        for (final hit in hits)
          if (hit != null) hit.queriedFeature.feature,
      ];
      if (features.isEmpty) return;

      // Ưu tiên cluster nếu vùng chạm trúng cả cluster lẫn điểm lẻ
      final cluster = features.where(_isCluster).firstOrNull;
      if (cluster != null) {
        await _onClusterTap(cluster, gestureContext);
      } else {
        _onPointTap(features.first);
      }
    } catch (e) {
      debugPrint('[MapScreen] Map tap query failed — $e');
    }
  }

  static Map<Object?, Object?> _propertiesOf(Map<String?, Object?> feature) =>
      (feature['properties'] as Map?) ?? const {};

  static bool _isCluster(Map<String?, Object?> feature) =>
      _propertiesOf(feature).containsKey('point_count');

  Future<void> _onClusterTap(
    Map<String?, Object?> cluster,
    MapContentGestureContext gestureContext,
  ) async {
    final map = _mapboxMap;
    if (map == null) return;

    final properties = _propertiesOf(cluster);
    final center = _pointOf(cluster['geometry']) ?? gestureContext.point;

    try {
      final expansion = await map.getGeoJsonClusterExpansionZoom(
        ReportClusterLayer.sourceId,
        cluster,
      );
      final expansionZoom = double.tryParse(expansion.value ?? '');

      // Tầng 1: zoom vào được → bay tới mức zoom mà cluster tách ra
      if (expansionZoom != null &&
          expansionZoom <= ReportClusterLayer.clusterMaxZoom) {
        await _easeTo(center, expansionZoom);
        return;
      }

      // Tầng 2: không tách được nữa → mở danh sách report trong cluster
      final pointCount = (properties['point_count'] as num?)?.toInt() ?? 0;
      final leaves = await map.getGeoJsonClusterLeaves(
        ReportClusterLayer.sourceId,
        cluster,
        pointCount,
        0,
      );
      final ids = <String>{
        for (final leaf in leaves.featureCollection ?? const [])
          if ((leaf?['properties'] as Map?)?['id'] case final String id) id,
      };
      final reports = _visibleReports.where((r) => ids.contains(r.id)).toList();
      if (reports.isNotEmpty && mounted) _showClusterSheet(reports);
    } catch (e) {
      // Không đọc được thông tin cluster → vẫn phản hồi bằng cách zoom vào thêm
      debugPrint('[MapScreen] Cluster tap failed — $e');
      final camera = await map.getCameraState();
      await _easeTo(
        center,
        (camera.zoom + 2).clamp(0, ReportClusterLayer.clusterMaxZoom + 1).toDouble(),
      );
    }
  }

  Future<void> _easeTo(Point center, double zoom) async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await map.easeTo(
      CameraOptions(center: center, zoom: zoom),
      MapAnimationOptions(duration: reduceMotion ? 0 : 500),
    );
  }

  void _onPointTap(Map<String?, Object?> feature) {
    final id = _propertiesOf(feature)['id'];
    for (final report in _visibleReports) {
      if (report.id == id) {
        _showReportInfo(report);
        return;
      }
    }
  }

  Point? _pointOf(Object? geometry) {
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

  void _openReportDetail(ReportModel report) {
    context.push(RouterPath.reportDetail.replaceAll(':id', report.id));
  }

  void _showReportInfo(ReportModel report) {
    if (!mounted) return;
    ref.read(mapControllerProvider.notifier).selectReport(report);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ReportInfoSheet(
        report: report,
        onViewDetail: () {
          Navigator.of(sheetContext).pop();
          _openReportDetail(report);
        },
      ),
    ).whenComplete(() {
      if (mounted) ref.read(mapControllerProvider.notifier).clearSelection();
    });
  }

  void _showClusterSheet(List<ReportModel> reports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MapClusterSheet(
        reports: reports,
        onReportTap: (report) {
          Navigator.of(sheetContext).pop();
          _openReportDetail(report);
        },
      ),
    );
  }

  /// Bật location puck (chấm vị trí người dùng) trên bản đồ
  void _enableLocationPuck() async {
    if (_mapboxMap == null) return;
    final info = AppSemanticColors.of(context).info;

    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: info.toARGB32(),
        pulsingMaxRadius: 30.0,
        showAccuracyRing: true,
        accuracyRingColor: info.withValues(alpha: 0.15).toARGB32(),
        accuracyRingBorderColor: info.withValues(alpha: 0.3).toARGB32(),
      ),
    );
  }

  void _flyToUserLocation() async {
    final pos = await locationService.getCurrentPosition();
    if (pos == null || _mapboxMap == null) return;

    _enableLocationPuck();

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
        zoom: 15.0,
        pitch: 0.0,
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mapState = ref.watch(mapControllerProvider);
    final reportsState = ref.watch(mapReportsProvider);

    // Dữ liệu hoặc filter đổi → cập nhật source của bản đồ
    ref.listen(mapReportsProvider.select((s) => s.reports), (_, _) => _syncReports());
    ref.listen(
      mapControllerProvider.select((s) => (s.showDangerous, s.showNormal)),
      (_, _) => _syncReports(),
    );
    ref.listen(mapReportsProvider.select((s) => s.error), (previous, next) {
      if (next == null || previous != null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mapLoadReportsFailed),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: () => ref.read(mapControllerProvider.notifier).refresh(),
            ),
          ),
        );
    });

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onMapIdleListener: _onMapIdle,
            styleUri: MapboxStyles.STANDARD,
          ),

          if (reportsState.isLoading)
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(minHeight: 2),
            ),

          if (reportsState.truncated)
            Positioned(
              top: topInset + 12,
              left: 72,
              right: 72,
              child: Center(child: _ZoomInHint(label: l10n.mapZoomInForMore)),
            ),

          MapControls(
            showDangerous: mapState.showDangerous,
            showNormal: mapState.showNormal,
            onMyLocationPressed: _flyToUserLocation,
            onFilterChanged: ({bool? showDangerous, bool? showNormal}) {
              if (showDangerous != null) {
                ref.read(mapControllerProvider.notifier).toggleDangerous();
              }
              if (showNormal != null) {
                ref.read(mapControllerProvider.notifier).toggleNormal();
              }
            },
            onRefreshPressed: () {
              ref.read(mapControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }
}

/// Gợi ý phóng to khi khung nhìn có nhiều report hơn giới hạn tải.
class _ZoomInHint extends StatelessWidget {
  final String label;

  const _ZoomInHint({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 2,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.zoom_in_rounded, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
