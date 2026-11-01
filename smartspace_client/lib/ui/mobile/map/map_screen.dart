import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/map_reports_provider.dart';
import 'package:smartspace_client/features/reports/providers/report_density_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/components/density_map_layer.dart';
import 'package:smartspace_client/ui/components/map_cluster_sheet.dart';
import 'package:smartspace_client/ui/components/map_controls.dart';
import 'package:smartspace_client/ui/components/map_density_legend.dart';
import 'package:smartspace_client/ui/components/map_settings_bottom_sheet.dart';
import 'package:smartspace_client/ui/components/marker_image_generator.dart';
import 'package:smartspace_client/ui/components/report_info_sheet.dart';
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';

/// Mobile Map Screen — report theo khung nhìn, gom cụm (cluster),
/// và hiển thị bản đồ mật độ phản ánh H3 (50m, scale 1.5x) lưu Redis.
class MobileMapScreen extends ConsumerStatefulWidget {
  final MapFocusTarget? focus;

  const MobileMapScreen({super.key, this.focus});

  @override
  ConsumerState<MobileMapScreen> createState() => _MobileMapScreenState();
}

class _MobileMapScreenState extends ConsumerState<MobileMapScreen> {
  MapboxMap? _mapboxMap;
  ClusterMapLayer? _clusterLayer;
  DensityMapLayer? _densityLayer;
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
    _densityLayer = DensityMapLayer(map: mapboxMap);
    _clusterLayer = ClusterMapLayer(
      map: mapboxMap,
      imageBuilder: _buildMarkerImage,
      colors: _colors ?? ClusterLayerColors.fromTheme(Theme.of(context)),
      pixelRatio: _pixelRatio,
      imageWidth: MarkerImageGenerator.markerWidth,
      imageHeight: MarkerImageGenerator.markerHeight,
    );

    // Bắt tap ở mức bản đồ, layer tự query feature gốc từ source
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

  /// Style load xong (kể cả reload) → thêm lại source/layer rồi tải dữ liệu mới nhất từ API.
  void _onStyleLoaded(StyleLoadedEventData _) async {
    final densityGeojson = ref.read(reportDensityProvider).geojsonString;
    await _densityLayer?.install(geojsonString: densityGeojson);
    if (!ref.read(reportDensityProvider).isEnabled) {
      await _densityLayer?.setVisible(false);
    }

    await _clusterLayer?.install(_visibleReports.map(_toMarker).toList());
    // Luôn ép gọi API lấy dữ liệu mới nhất mỗi khi mở giao diện bản đồ
    _emitViewport(force: true);
  }

  void _onMapIdle(MapIdleEventData _) {
    _emitViewport();
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    _clusterLayer?.loadVisibleImages(size.width, size.height);
  }

  Future<void> _emitViewport({bool force = false}) async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    try {
      final bounds = await ClusterMapLayer.readViewport(map);
      if (!mounted || bounds == null) return;
      ref.read(mapControllerProvider.notifier).onViewportChanged(bounds, force: force);

      final camera = await map.getCameraState();
      ref.read(reportDensityProvider.notifier).loadForViewport(bounds, camera.zoom, force: force);
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

  void _showMapSettings() {
    final isEnabled = ref.read(reportDensityProvider).isEnabled;
    final currentFilter = ref.read(mapReportsProvider).filter;

    MapSettingsBottomSheet.show(
      context,
      isDensityEnabled: isEnabled,
      currentFilter: currentFilter,
      onDensityToggle: (val) async {
        final map = _mapboxMap;
        MapBounds? bounds;
        double? zoom;
        if (map != null) {
          bounds = await ClusterMapLayer.readViewport(map);
          final camera = await map.getCameraState();
          zoom = camera.zoom;
        }
        ref.read(reportDensityProvider.notifier).toggleEnabled(bounds: bounds, zoom: zoom);
      },
      onFilterSelected: (filter) {
        ref.read(mapControllerProvider.notifier).setFilter(filter);
      },
    );
  }

  void _onBackPressed() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouterPath.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mapState = ref.watch(mapControllerProvider);
    final reportsState = ref.watch(mapReportsProvider);
    final densityState = ref.watch(reportDensityProvider);

    // Sync reports with Mapbox cluster layer
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

    // Listen to Density GeoJSON updates
    ref.listen(reportDensityProvider.select((s) => s.geojsonString), (_, geojson) {
      if (ref.read(reportDensityProvider).isEnabled) {
        _densityLayer?.updateData(geojson);
        _densityLayer?.setVisible(true);
      }
    });

    // Listen to Density Toggle on/off
    ref.listen(reportDensityProvider.select((s) => s.isEnabled), (_, isEnabled) {
      _densityLayer?.setVisible(isEnabled);
      if (isEnabled) {
        _emitViewport(force: true);
      }
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

          if (reportsState.isLoading || (densityState.isEnabled && densityState.isLoading))
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(minHeight: 2),
            ),

          // Back Button — Top Left (chống cụt luồng điều hướng, góc trên thoáng đãng)
          Positioned(
            top: topInset + 12,
            left: 12,
            child: MapControlButton(
              icon: Icons.arrow_back,
              tooltip: l10n.mapBack,
              onPressed: _onBackPressed,
              colorScheme: colorScheme,
            ),
          ),

          if (reportsState.truncated || (densityState.isEnabled && densityState.truncated))
            Positioned(
              top: topInset + 16,
              left: 64,
              right: 64,
              child: Center(child: _ZoomInHint(label: l10n.mapZoomInForMore)),
            ),

          // Density Legend — Bottom Left (chỉ hiện khi tính năng bật)
          if (densityState.isEnabled)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 12,
              child: const MapDensityLegend(),
            ),

          // Map Controls — Right Column (Settings, My Location, Filters, Refresh)
          MapControls(
            showDangerous: mapState.showDangerous,
            showNormal: mapState.showNormal,
            isDensityActive: densityState.isEnabled,
            onSettingsPressed: _showMapSettings,
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
              _emitViewport(force: true);
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
