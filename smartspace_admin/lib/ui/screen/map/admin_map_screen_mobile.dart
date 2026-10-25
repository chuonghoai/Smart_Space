import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';
import 'widgets/map_cluster_colors.dart';
import 'widgets/marker_image_generator.dart';

/// Mobile/Desktop map — uses mapbox_maps_flutter native SDK, report gom cụm (cluster).
Widget buildPlatformMap({
  required BuildContext context,
  required List<MapReportModel> reports,
  required void Function(MapReportModel report) onMarkerTap,
  required void Function(List<MapReportModel> reports) onClusterTap,
  required void Function(MapBounds bounds) onViewportChanged,
  VoidCallback? onMapTap,
}) {
  return _MobileMapView(
    reports: reports,
    onMarkerTap: onMarkerTap,
    onClusterTap: onClusterTap,
    onViewportChanged: onViewportChanged,
    onMapTap: onMapTap,
  );
}

class _MobileMapView extends StatefulWidget {
  final List<MapReportModel> reports;
  final void Function(MapReportModel report) onMarkerTap;
  final void Function(List<MapReportModel> reports) onClusterTap;
  final void Function(MapBounds bounds) onViewportChanged;
  final VoidCallback? onMapTap;

  const _MobileMapView({
    required this.reports,
    required this.onMarkerTap,
    required this.onClusterTap,
    required this.onViewportChanged,
    this.onMapTap,
  });

  @override
  State<_MobileMapView> createState() => _MobileMapViewState();
}

class _MobileMapViewState extends State<_MobileMapView> {
  MapboxMap? _mapboxMap;
  ClusterMapLayer? _clusterLayer;
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  ClusterLayerColors? _colors;
  double _pixelRatio = 1;

  /// Màu viền marker theo trạng thái, đọc từ theme mỗi khi theme đổi.
  Map<String, Color> _statusColors = const {};

  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixelRatio = MediaQuery.of(context).devicePixelRatio;
    _statusColors = {
      for (final status in const ['pending', 'processing', 'processed', 'rejected'])
        status: reportStatusColor(context, status),
    };
    final colors = adminClusterColors(context);
    if (colors != _colors) {
      _colors = colors;
      _clusterLayer?.updateColors(colors);
    }
  }

  @override
  void didUpdateWidget(covariant _MobileMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reports != widget.reports) {
      _clusterLayer?.setMarkers(_markers());
    }
  }

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
  }

  /// Report chờ xử lý (pending) là việc cần làm → nổi bật cả ở marker lẫn cluster.
  List<ClusterMarker> _markers() => [
        for (final report in widget.reports)
          ClusterMarker(
            id: report.id,
            latitude: report.latitude,
            longitude: report.longitude,
            imageUrl: report.imageUrl ?? '',
            isAlert: report.isPending,
            isEmphasized: report.isPending,
            styleKey: report.status,
          ),
      ];

  Future<Uint8List> _buildMarkerImage(ClusterMarker marker, {required bool withPhoto}) {
    return _markerGenerator.generateMarkerImage(
      imageUrl: withPhoto ? marker.imageUrl : '',
      borderColor: _statusColors[marker.styleKey] ?? Theme.of(context).colorScheme.outline,
      cacheKey: withPhoto ? marker.id : 'fallback-${marker.styleKey}',
      showRadarRings: marker.isAlert,
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _clusterLayer = ClusterMapLayer(
      map: mapboxMap,
      imageBuilder: _buildMarkerImage,
      colors: _colors ?? adminClusterColors(context),
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
  }

  /// Style load xong (kể cả reload) → thêm lại source/layer rồi báo khung nhìn.
  void _onStyleLoaded(StyleLoadedEventData _) async {
    await _clusterLayer?.install(_markers());
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
      if (mounted && bounds != null) widget.onViewportChanged(bounds);
    } catch (e) {
      debugPrint('[AdminMap] Failed to read viewport — $e');
    }
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
        final report = widget.reports.where((r) => r.id == id).firstOrNull;
        if (report != null) widget.onMarkerTap(report);
      case ClusterLeavesTapped(:final ids):
        final reports = widget.reports.where((r) => ids.contains(r.id)).toList();
        if (reports.isNotEmpty) widget.onClusterTap(reports);
      case ClusterZoomedIn():
        break;
      case null:
        widget.onMapTap?.call();
    }
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onMapIdleListener: _onMapIdle,
          styleUri: MapboxStyles.STANDARD,
        ),
        // My location button
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'map_location',
            onPressed: () async {
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
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
