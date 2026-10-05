// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';
import 'package:smartspace_staff/ui/mobile/map/map_controller.dart';
import 'package:smartspace_staff/ui/mobile/map/marker_image_generator.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/ui/mobile/map/map_controls.dart';
import 'package:smartspace_staff/ui/mobile/map/report_info_sheet.dart';

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onClick;
  _AnnotationClickListener(this.onClick);
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onClick(annotation);
  }
}

/// Mobile Map Screen for Staff
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  final Map<String, ReportModel> _annotationToReport = {};
  final MarkerImageGenerator _markerGenerator = MarkerImageGenerator();

  // HCM city center
  static final _defaultCenter = Point(coordinates: Position(106.6297, 10.8231));

  @override
  void initState() {
    super.initState();
    // Refresh assignments when entering map if needed, 
    // but typically it's already loaded by HomeController.
  }

  @override
  void dispose() {
    _markerGenerator.clearCache();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
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
    _enableLocationPuck();
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
    if (_annotationManager == null) return;

    await _annotationManager!.deleteAll();
    _annotationToReport.clear();

    final mapState = ref.read(mapControllerProvider);
    final homeState = ref.read(homeControllerProvider);
    final reports = mapState.getFilteredReports(homeState);

    const Color tealPrimary = Color(0xFF00796B);

    for (final report in reports) {
      if (report.latitude == 0 && report.longitude == 0) continue;

      final isDangerous = report.severity == ReportSeverity.critical || report.severity == ReportSeverity.high;
      final borderColor = isDangerous ? Colors.red : tealPrimary;

      final imageBytes = await _markerGenerator.generateMarkerImage(
        imageUrl: report.imageUrl,
        borderColor: borderColor,
        cacheKey: report.id,
        isDangerous: isDangerous,
      );

      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(report.longitude, report.latitude),
          ),
          image: imageBytes,
          iconSize: isDangerous ? 0.55 : 0.45,
        ),
      );

      _annotationToReport[annotation.id] = report;
    }
  }

  void _onAnnotationClick(PointAnnotation annotation) {
    final report = _annotationToReport[annotation.id];
    if (report != null) {
      ref.read(mapControllerProvider.notifier).selectReport(report);
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ReportInfoSheet(report: report),
      ).whenComplete(() {
        ref.read(mapControllerProvider.notifier).clearSelection();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi homeState & mapState để update marker
    ref.listen(homeControllerProvider, (_, _) => _updateMarkers());
    ref.listen(mapControllerProvider, (_, _) => _updateMarkers());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                )
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
            styleUri: MapboxStyles.STANDARD,
          ),
          MapControls(
            showDangerous: ref.watch(mapControllerProvider).showDangerous,
            showRecent: ref.watch(mapControllerProvider).showRecent,
            onFilterChanged: ({showDangerous, showRecent}) {
              if (showDangerous != null) {
                ref.read(mapControllerProvider.notifier).toggleDangerous();
              }
              if (showRecent != null) {
                ref.read(mapControllerProvider.notifier).toggleRecent();
              }
            },
            onMyLocationPressed: () async {
              if (_mapboxMap == null) return;
              final homeState = ref.read(homeControllerProvider);
              if (homeState.currentPosition != null) {
                _mapboxMap!.flyTo(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(
                        homeState.currentPosition!.longitude,
                        homeState.currentPosition!.latitude,
                      ),
                    ),
                    zoom: 15.0,
                  ),
                  MapAnimationOptions(duration: 1000),
                );
              }
            },
            onRefreshPressed: () {
              // TODO: Implement refresh logic for staff
            },
          ),
        ],
      ),
    );
  }
}
