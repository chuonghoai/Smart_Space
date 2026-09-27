import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'widgets/marker_image_generator.dart';

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onClick;
  _AnnotationClickListener(this.onClick);
  @override
  void onPointAnnotationClick(PointAnnotation annotation) => onClick(annotation);
}

/// Mobile/Desktop map — uses mapbox_maps_flutter native SDK
Widget buildPlatformMap({
  required BuildContext context,
  required List<MapReportModel> reports,
  void Function(MapReportModel report)? onMarkerTap,
  VoidCallback? onMapTap,
}) {
  return _MobileMapView(
    reports: reports,
    onMarkerTap: onMarkerTap,
    onMapTap: onMapTap,
  );
}

class _MobileMapView extends StatefulWidget {
  final List<MapReportModel> reports;
  final void Function(MapReportModel report)? onMarkerTap;
  final VoidCallback? onMapTap;

  const _MobileMapView({
    required this.reports,
    this.onMarkerTap,
    this.onMapTap,
  });

  @override
  State<_MobileMapView> createState() => _MobileMapViewState();
}

class _MobileMapViewState extends State<_MobileMapView> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  final Map<String, MapReportModel> _annotationToReport = {};
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _annotationManager!.addOnPointAnnotationClickListener(
      _AnnotationClickListener(_onAnnotationClick),
    );

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

    _updateMarkers();
  }

  void _enableLocationPuck() async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: Colors.blue.toARGB32(),
        pulsingMaxRadius: 30.0,
        showAccuracyRing: true,
        accuracyRingColor: Colors.blue.withValues(alpha: 0.15).toARGB32(),
        accuracyRingBorderColor: Colors.blue.withValues(alpha: 0.3).toARGB32(),
      ),
    );
  }

  void _updateMarkers() async {
    if (_annotationManager == null || !mounted) return;

    final brightness = Theme.of(context).brightness;
    final cs = Theme.of(context).colorScheme;

    await _annotationManager!.deleteAll();
    if (!mounted) return;
    _annotationToReport.clear();

    for (final report in widget.reports) {
      if (report.latitude == 0 && report.longitude == 0) continue;

      final borderColor = report.statusColorAdaptive(cs, brightness);

      final imageBytes = await _markerGenerator.generateMarkerImage(
        imageUrl: report.imageUrl ?? '',
        borderColor: borderColor,
        cacheKey: report.id,
        showRadarRings: report.isPending,
      );

      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(report.longitude, report.latitude),
          ),
          image: imageBytes,
          iconSize: report.isPending ? 0.55 : 0.45,
        ),
      );

      _annotationToReport[annotation.id] = report;
    }
  }

  void _onAnnotationClick(PointAnnotation annotation) {
    final report = _annotationToReport[annotation.id];
    if (report != null) {
      widget.onMarkerTap?.call(report);
    }
  }

  @override
  void didUpdateWidget(covariant _MobileMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reports != widget.reports) {
      _updateMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          onMapCreated: _onMapCreated,
          styleUri: MapboxStyles.STANDARD,
          onTapListener: (_) {
            widget.onMapTap?.call();
          },
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
