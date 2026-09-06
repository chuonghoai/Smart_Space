import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_providers.dart';
import 'package:smartspace_client/ui/shared/components/map_controls.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/shared/components/report_info_sheet.dart';

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onClick;
  _AnnotationClickListener(this.onClick);
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onClick(annotation);
  }
}

/// Mobile Map Screen — Mapbox 3D
class MobileMapScreen extends ConsumerStatefulWidget {
  const MobileMapScreen({super.key});

  @override
  ConsumerState<MobileMapScreen> createState() => _MobileMapScreenState();
}

class _MobileMapScreenState extends ConsumerState<MobileMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  final Map<String, ReportModel> _annotationToReport = {};

  // HCM city center
  static final _defaultCenter = Point(
    coordinates: Position(106.6297, 10.8231),
  );

  @override
  void initState() {
    super.initState();
    // Refresh reports khi vào map
    Future.microtask(() {
      ref.read(reportsProvider.notifier).refreshAll();
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _annotationManager!.addOnPointAnnotationClickListener(
      _AnnotationClickListener(_onAnnotationClick),
    );

    // Set 3D camera
    await mapboxMap.setCamera(CameraOptions(
      center: _defaultCenter,
      zoom: 12.0,
      pitch: 45.0,
      bearing: 0.0,
    ));

    // Enable 3D terrain
    await mapboxMap.style.setStyleImportConfigProperty(
      'basemap',
      'showRoadsAndTransit',
      true,
    );

    _updateMarkers();
  }

  void _updateMarkers() async {
    if (_annotationManager == null) return;

    // Xóa markers cũ
    await _annotationManager!.deleteAll();
    _annotationToReport.clear();

    final mapState = ref.read(mapControllerProvider);
    final reportsState = ref.read(reportsProvider);
    final reports = mapState.getFilteredReports(reportsState);

    debugPrint('[MapCtrl] Valid reports after filter: ${reports.length}');

    for (final report in reports) {
      if (report.latitude == 0 && report.longitude == 0) continue;

      final isDangerous = reportsState.dangerousReports.contains(report);

      final annotation = await _annotationManager!.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(report.longitude, report.latitude),
        ),
        iconSize: 1.5,
        iconColor: isDangerous ? Colors.red.toARGB32() : Colors.blue.toARGB32(),
        textField: report.title,
        textSize: 10.0,
        textOffset: [0.0, 1.5],
      ));
      
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
        builder: (_) => ReportInfoSheet(
          report: report,
          onViewDetail: () {
            Navigator.of(context).pop();
            context.push('${RouterPath.createReport}?id=${report.id}');
          },
        ),
      );
    }
  }

  void _flyToUserLocation() async {
    final pos = await locationService.getCurrentPosition();
    if (pos == null || _mapboxMap == null) return;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(pos.longitude, pos.latitude),
        ),
        zoom: 14.0,
        pitch: 45.0,
      ),
      MapAnimationOptions(duration: 1500),
    );
  }



  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);


    // Listen to filter changes → update markers
    ref.listen(mapControllerProvider, (prev, next) {
      if (prev?.showDangerous != next.showDangerous ||
          prev?.showRecent != next.showRecent) {
        _updateMarkers();
      }
    });

    // Listen to report data changes → update markers
    ref.listen(reportsProvider, (prev, next) {
      _updateMarkers();
    });

    return Scaffold(
      body: Stack(
        children: [
          // BẢN ĐỒ MAPBOX 3D
          MapWidget(
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.STANDARD,
          ),

          // NÚT ĐIỀU KHIỂN
          MapControls(
            showDangerous: mapState.showDangerous,
            showRecent: mapState.showRecent,
            onMyLocationPressed: _flyToUserLocation,
            onFilterChanged: ({bool? showDangerous, bool? showRecent}) {
              if (showDangerous != null) {
                ref.read(mapControllerProvider.notifier).toggleDangerous();
              }
              if (showRecent != null) {
                ref.read(mapControllerProvider.notifier).toggleRecent();
              }
            },
            onRefreshPressed: () {
              ref.read(reportsProvider.notifier).refreshAll();
            },
          ),
        ],
      ),
    );
  }
}
