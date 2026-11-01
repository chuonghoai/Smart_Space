import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/map_reports_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/components/map_cluster_sheet.dart';
import 'package:smartspace_client/ui/components/map_controls.dart';
import 'package:smartspace_client/ui/components/map_filter_bar.dart';
import 'package:smartspace_client/ui/components/marker_image_generator.dart';
import 'package:smartspace_client/ui/components/report_info_sheet.dart';
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';

/// Mobile Map Screen — report theo khung nhìn, gom cụm (cluster).
///
/// Bấm cluster: zoom tới mức cluster tách ra; nếu không tách được nữa
/// (trùng/sát toạ độ) thì mở danh sách report trong cluster.
///
/// Có [focus] (mở từ chi tiết report) → camera mở tại report đó; lần tải đầu xong thì
/// mở thẻ thông tin của nó, hoặc báo nếu nó không hiện trên bản đồ (vd. bị bộ lọc ẩn).
class MobileMapScreen extends ConsumerStatefulWidget {
  final MapFocusTarget? focus;

  const MobileMapScreen({super.key, this.focus});

  @override
  ConsumerState<MobileMapScreen> createState() => _MobileMapScreenState();
}

class _MobileMapScreenState extends ConsumerState<MobileMapScreen> {
  MapboxMap? _mapboxMap;
  ClusterMapLayer? _clusterLayer;
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  ClusterLayerColors? _colors;
  double _pixelRatio = 1;

  /// Report đang vẽ trên bản đồ (đã áp filter).
  List<ReportModel> _visibleReports = const [];
  bool _didHandleFocus = false;

  // HCM city center
  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final colors = ClusterLayerColors.fromTheme(Theme.of(context));
    if (colors != _colors) {
      _colors = colors;
      _clusterLayer?.updateColors(colors);
    }
  }

  static ClusterMarker _toMarker(ReportModel report) => ClusterMarker(
        id: report.id,
        latitude: report.latitude,
        longitude: report.longitude,
        imageUrl: report.imageUrl,
        isAlert: report.isDangerous,
        isEmphasized: report.isDangerous,
        styleKey: report.isDangerous ? 'd' : 'n',
      );

  /// Viền đỏ (error) cho report nguy hiểm, primary cho report thường.
  Future<Uint8List> _buildMarkerImage(ClusterMarker marker, {required bool withPhoto}) {
    final colors = _colors ?? ClusterLayerColors.fromTheme(Theme.of(context));
    return _markerGenerator.generateMarkerImage(
      imageUrl: withPhoto ? marker.imageUrl : '',
      borderColor: marker.isAlert ? colors.alert : colors.normal,
      cacheKey: withPhoto ? marker.id : 'fallback-${marker.styleKey}',
      isDangerous: marker.isAlert,
    );
  }

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
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
    // (không phụ thuộc việc layer cluster đã tồn tại lúc đăng ký).
    mapboxMap.addInteraction(
      TapInteraction.onMap(_onMapTap, stopPropagation: false),
    );

    // Set 2D top-down camera (radar view)
    final focus = widget.focus;
    await mapboxMap.setCamera(
      CameraOptions(
        center: focus != null
            ? Point(coordinates: Position(focus.longitude, focus.latitude))
            : _defaultCenter,
        zoom: focus != null ? MapFocusTarget.zoom : 12.0,
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
    await _clusterLayer?.install(_visibleReports.map(_toMarker).toList());
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
      final bounds = await ClusterMapLayer.readViewport(map);
      if (!mounted || bounds == null) return;
      ref.read(mapControllerProvider.notifier).onViewportChanged(bounds);
    } catch (e) {
      debugPrint('[MapScreen] Failed to read viewport — $e');
    }
  }

  void _syncReports() {
    final filtered = ref
        .read(mapControllerProvider)
        .getFilteredReports(ref.read(mapReportsProvider).reports);
    _visibleReports = filtered;
    _clusterLayer?.setMarkers(filtered.map(_toMarker).toList());
  }

  /// Lần tải thành công đầu tiên (camera đang ở report được focus) → mở thẻ của report đó,
  /// hoặc báo nó không hiện trên bản đồ.
  void _handleFocusOnce() {
    final focus = widget.focus;
    if (focus == null || _didHandleFocus) return;
    _didHandleFocus = true;

    // Mở sheet sau frame hiện tại: lời gọi đến từ listener của provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final report = _visibleReports.where((r) => r.id == focus.reportId).firstOrNull;
      if (report != null) {
        _showReportInfo(report);
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mapFocusedReportHidden)),
        );
    });
  }

  /// Điểm lẻ → thẻ thông tin; cluster tách được → layer đã zoom vào;
  /// cluster không tách được nữa → danh sách report trong cluster.
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
        if (report != null) _showReportInfo(report);
      case ClusterLeavesTapped(:final ids):
        final reports = _visibleReports.where((r) => ids.contains(r.id)).toList();
        if (reports.isNotEmpty) _showClusterSheet(reports);
      case ClusterZoomedIn() || null:
        break;
    }
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

    // Dữ liệu hoặc filter đổi → cập nhật source của bản đồ.
    // Mỗi lần tải thành công trả list mới → listener này cũng đánh dấu "đã có dữ liệu" cho focus.
    ref.listen(mapReportsProvider.select((s) => s.reports), (_, _) {
      _syncReports();
      _handleFocusOnce();
    });
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

          // Chừa cột nút điều khiển bên phải (12 lề + 42 nút + 8 khoảng cách)
          Positioned(
            top: topInset + 8,
            left: 0,
            right: 62,
            child: MapFilterBar(
              selected: reportsState.filter,
              onSelected: (filter) =>
                  ref.read(mapControllerProvider.notifier).setFilter(filter),
            ),
          ),

          if (reportsState.truncated)
            Positioned(
              top: topInset + 64,
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
