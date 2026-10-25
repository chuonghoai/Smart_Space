import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo show Position;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/providers/staff_map_reports_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/map/map_cluster_sheet.dart';
import 'package:smartspace_staff/ui/mobile/map/map_controller.dart';
import 'package:smartspace_staff/ui/mobile/map/map_controls.dart';
import 'package:smartspace_staff/ui/mobile/map/marker_image_generator.dart';
import 'package:smartspace_staff/ui/mobile/map/report_info_sheet.dart';
import 'package:smartspace_staff/ui/shared/utils/open_in_google_maps.dart';

/// Mobile Map Screen for Staff — mọi việc đang xử lý, gom cụm (cluster).
///
/// Bấm cluster: zoom tới mức cluster tách ra; nếu không tách được nữa
/// (trùng/sát toạ độ) thì mở danh sách việc, sắp gần nhất trước khi có GPS.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  ClusterMapLayer? _clusterLayer;
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  ClusterLayerColors? _colors;
  double _pixelRatio = 1;
  Color _rehandlingColor = Colors.transparent;

  /// Việc đang vẽ trên bản đồ (đã áp filter).
  List<ReportModel> _visibleReports = const [];
  geo.Position? _userPosition;
  bool _didFitInitialCamera = false;

  // HCM city center
  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixelRatio = MediaQuery.of(context).devicePixelRatio;
    _rehandlingColor = AppSemanticColors.of(context).warning;
    final colors = ClusterLayerColors.fromTheme(Theme.of(context));
    if (colors != _colors) {
      _colors = colors;
      _clusterLayer?.updateColors(colors);
    }
  }

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
  }

  Future<void> _loadUserPosition() async {
    final position = await locationService.getCurrentPosition();
    if (!mounted || position == null) return;
    setState(() => _userPosition = position);
  }

  /// Nguy hiểm → error (cụm cũng tô error); cần xử lý lại → warning; còn lại → primary.
  static String _styleKey(ReportModel report) {
    if (report.isDangerous) return 'danger';
    if (report.needsRehandling) return 'rehandling';
    return 'normal';
  }

  static ClusterMarker _toMarker(ReportModel report) => ClusterMarker(
        id: report.id,
        latitude: report.latitude,
        longitude: report.longitude,
        imageUrl: report.imageUrl,
        isAlert: report.isDangerous,
        isEmphasized: report.isDangerous,
        styleKey: _styleKey(report),
      );

  Future<Uint8List> _buildMarkerImage(ClusterMarker marker, {required bool withPhoto}) {
    final colors = _colors ?? ClusterLayerColors.fromTheme(Theme.of(context));
    final borderColor = switch (marker.styleKey) {
      'danger' => colors.alert,
      'rehandling' => _rehandlingColor,
      _ => colors.normal,
    };
    return _markerGenerator.generateMarkerImage(
      imageUrl: withPhoto ? marker.imageUrl : '',
      borderColor: borderColor,
      cacheKey: withPhoto ? marker.id : 'fallback-${marker.styleKey}',
      isDangerous: marker.isAlert,
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _clusterLayer = ClusterMapLayer(
      map: mapboxMap,
      imageBuilder: _buildMarkerImage,
      colors: _colors ?? ClusterLayerColors.fromTheme(Theme.of(context)),
      pixelRatio: _pixelRatio,
      imageWidth: MarkerImageGenerator.markerWidth,
      imageHeight: MarkerImageGenerator.markerHeight,
    );

    // Bắt tap ở mức bản đồ, layer tự query feature gốc từ source
    mapboxMap.addInteraction(TapInteraction.onMap(_onMapTap, stopPropagation: false));

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

    _enableLocationPuck();
  }

  /// Style load xong (kể cả reload) → thêm lại source/layer với việc hiện có.
  void _onStyleLoaded(StyleLoadedEventData _) async {
    await _clusterLayer?.install(_visibleReports.map(_toMarker).toList());
    _fitInitialCameraOnce();
  }

  void _onMapIdle(MapIdleEventData _) {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    _clusterLayer?.loadVisibleImages(size.width, size.height);
  }

  void _syncReports() {
    final reports = ref.read(staffMapReportsProvider).valueOrNull?.reports ?? const [];
    _visibleReports = ref.read(mapControllerProvider).getFilteredReports(reports);
    _clusterLayer?.setMarkers(_visibleReports.map(_toMarker).toList());
    _fitInitialCameraOnce();
  }

  /// Lần đầu có dữ liệu → căn camera thấy mọi việc, để staff không phải tự kéo tìm.
  void _fitInitialCameraOnce() {
    if (_didFitInitialCamera || _mapboxMap == null) return;
    final reports = ref.read(staffMapReportsProvider).valueOrNull?.reports;
    if (reports == null || reports.isEmpty) return;
    _didFitInitialCamera = true;
    _showAllTasks();
  }

  /// Căn camera bao mọi việc được giao (đã lọc) + vị trí staff (nếu có).
  Future<void> _showAllTasks() async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;

    final points = [
      for (final r in _visibleReports) Point(coordinates: Position(r.longitude, r.latitude)),
      if (_userPosition case final p?) Point(coordinates: Position(p.longitude, p.latitude)),
    ];
    if (points.isEmpty) return;

    final padding = MediaQuery.paddingOf(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    try {
      final camera = points.length == 1
          ? CameraOptions(center: points.single, zoom: 15)
          : await map.cameraForCoordinatesPadding(
              points,
              CameraOptions(pitch: 0, bearing: 0),
              // Chừa chỗ cho app bar (trên) và cột nút điều khiển (phải)
              MbxEdgeInsets(top: padding.top + 72, left: 48, bottom: 48, right: 88),
              ClusterMapLayer.clusterMaxZoom,
              null,
            );
      await map.easeTo(camera, MapAnimationOptions(duration: reduceMotion ? 0 : 800));
    } catch (e) {
      debugPrint('[StaffMap] Failed to fit camera — $e');
    }
  }

  /// Gắn khoảng cách từ vị trí staff (nếu có) để hiển thị và sắp gần nhất trước.
  List<ReportModel> _withDistances(List<ReportModel> reports) {
    final position = _userPosition;
    if (position == null) return reports;
    return [
      for (final r in reports)
        r.copyWith(
          distanceInMeters: locationService.calculateDistance(
            position.latitude,
            position.longitude,
            r.latitude,
            r.longitude,
          ),
        ),
    ];
  }

  Future<void> _onMapTap(MapContentGestureContext gestureContext) async {
    final layer = _clusterLayer;
    if (layer == null || !mounted) return;

    final result = await layer.handleTap(
      gestureContext,
      reduceMotion: MediaQuery.of(context).disableAnimations,
    );
    if (!mounted) return;

    switch (result) {
      case ClusterPointTapped(:final id):
        final report = _visibleReports.where((r) => r.id == id).firstOrNull;
        if (report != null) _showReportInfo(_withDistances([report]).single);
      case ClusterLeavesTapped(:final ids):
        final reports = _visibleReports.where((r) => ids.contains(r.id)).toList();
        if (reports.isNotEmpty) _showClusterSheet(_withDistances(reports));
      case ClusterZoomedIn() || null:
        break;
    }
  }

  void _openReportDetail(ReportModel report) {
    context.push(RouterPath.reportDetail.replaceAll(':id', report.id));
  }

  void _showReportInfo(ReportModel report) {
    ref.read(mapControllerProvider.notifier).selectReport(report);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ReportInfoSheet(
        report: report,
        onOpenInMaps: () => openInGoogleMaps(context, report.latitude, report.longitude),
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
        onOpenInMaps: (report) => openInGoogleMaps(context, report.latitude, report.longitude),
        onReportTap: (report) {
          Navigator.of(sheetContext).pop();
          _openReportDetail(report);
        },
      ),
    );
  }

  void _enableLocationPuck() async {
    if (_mapboxMap == null || !mounted) return;
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

  Future<void> _flyToUserLocation() async {
    final position = await locationService.getCurrentPosition();
    if (!mounted || position == null || _mapboxMap == null) return;
    setState(() => _userPosition = position);
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: MediaQuery.of(context).disableAnimations ? 0 : 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final mapState = ref.watch(mapControllerProvider);
    final reportsAsync = ref.watch(staffMapReportsProvider);
    final data = reportsAsync.valueOrNull;

    // Chỉ vẽ lại khi dữ liệu hoặc filter đổi (không vẽ lại khi chọn/bỏ chọn report)
    ref.listen(staffMapReportsProvider.select((s) => s.valueOrNull), (_, _) => _syncReports());
    ref.listen(
      mapControllerProvider.select((s) => (s.showDangerous, s.showNormal)),
      (_, _) => _syncReports(),
    );
    ref.listen(staffMapReportsProvider.select((s) => s.hasError), (previous, next) {
      if (!next || previous == true) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mapLoadReportsFailed),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: () => ref.read(staffMapReportsProvider.notifier).refresh(),
            ),
          ),
        );
    });

    final topInset = MediaQuery.of(context).padding.top;
    final hint = switch (data) {
      StaffMapReports(:final truncated) when truncated =>
        l10n.mapShowingFirstTasks(StaffMapReportsNotifier.limit),
      StaffMapReports(:final reports) when reports.isEmpty && !reportsAsync.isLoading =>
        l10n.mapNoActiveTasks,
      _ => null,
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onMapIdleListener: _onMapIdle,
            styleUri: MapboxStyles.STANDARD,
          ),

          if (reportsAsync.isLoading)
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(minHeight: 2),
            ),

          if (hint != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: Center(child: _MapHint(label: hint)),
            ),

          MapControls(
            showDangerous: mapState.showDangerous,
            showNormal: mapState.showNormal,
            onFilterChanged: ({showDangerous, showNormal}) {
              if (showDangerous != null) {
                ref.read(mapControllerProvider.notifier).toggleDangerous();
              }
              if (showNormal != null) {
                ref.read(mapControllerProvider.notifier).toggleNormal();
              }
            },
            onMyLocationPressed: _flyToUserLocation,
            onShowAllTasksPressed: _showAllTasks,
            onRefreshPressed: () => ref.read(staffMapReportsProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

/// Thông báo ngắn trên nền đặc (không đặt chữ trực tiếp lên bản đồ).
class _MapHint extends StatelessWidget {
  final String label;

  const _MapHint({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 2,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
        ),
      ),
    );
  }
}
