import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_providers.dart';
import 'package:smartspace_client/ui/shared/components/map_controls.dart';
import 'package:smartspace_client/ui/shared/components/report_info_sheet.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:go_router/go_router.dart';

@JS('window.__onSmartSpaceMarkerClick')
external set _onMarkerClick(JSFunction f);

/// Web Map Screen — Mapbox GL JS 3D
class WebMapScreen extends ConsumerStatefulWidget {
  const WebMapScreen({super.key});

  @override
  ConsumerState<WebMapScreen> createState() => _WebMapScreenState();
}

class _WebMapScreenState extends ConsumerState<WebMapScreen> {
  bool _mapReady = false;
  bool _mapboxJsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMapboxJS();
    
    _onMarkerClick = ((JSString idStr) {
      if (mounted) {
        _handleMarkerClick(idStr.toDart);
      }
    }).toJS;

    Future.microtask(() {
      ref.read(reportsProvider.notifier).refreshAll();
    });
  }

  void _loadMapboxJS() {
    final head = web.document.head!;
    final existing = web.document.querySelector('script[data-mapbox-gl]');
    if (existing != null) {
      setState(() => _mapboxJsLoaded = true);
      return;
    }

    // CSS
    final link = web.document.createElement('link') as web.HTMLLinkElement;
    link.rel = 'stylesheet';
    link.href = 'https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.css';
    head.append(link);

    // JS
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.js';
    script.setAttribute('data-mapbox-gl', 'true');
    script.addEventListener('load', ((web.Event event) {
      if (mounted) {
        setState(() => _mapboxJsLoaded = true);
      }
    }).toJS);
    head.append(script);
  }

  void _initMap() {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    
    _evalJS('''
      mapboxgl.accessToken = '$token';
      window.__smartspace_map = new mapboxgl.Map({
        container: document.getElementById('mapbox-container'),
        style: 'mapbox://styles/mapbox/standard',
        center: [106.6297, 10.8231],
        zoom: 12,
        pitch: 45,
        bearing: 0,
        antialias: true
      });
      window.__smartspace_markers = [];
      window.__smartspace_map.on('load', function() {
        // Enable 3D terrain if available
        window.__smartspace_map.addSource('mapbox-dem', {
          type: 'raster-dem',
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 512,
          maxzoom: 14
        });
        window.__smartspace_map.setTerrain({ source: 'mapbox-dem', exaggeration: 1.5 });
      });
    ''');

    setState(() => _mapReady = true);
  }

  void _updateMarkersJS(List<ReportModel> reports, ReportsState reportsState) {
    // Remove old markers
    _evalJS('''
      if (window.__smartspace_markers) {
        window.__smartspace_markers.forEach(function(m) { m.remove(); });
        window.__smartspace_markers = [];
      }
    ''');

    // Add new markers
    for (final report in reports) {
      if (report.latitude == 0 && report.longitude == 0) continue;

      final isDangerous = reportsState.dangerousReports.contains(report);
      final color = isDangerous ? '#EF4444' : '#3B82F6';
      _evalJS('''
        if (window.__smartspace_map) {
          var marker = new mapboxgl.Marker({ color: '$color' })
            .setLngLat([${report.longitude}, ${report.latitude}])
            .addTo(window.__smartspace_map);
          
          marker.getElement().addEventListener('click', function(e) {
            e.stopPropagation();
            if (window.__onSmartSpaceMarkerClick) {
              window.__onSmartSpaceMarkerClick('${report.id}');
            }
          });
          
          window.__smartspace_markers.push(marker);
        }
      ''');
    }
  }

  void _handleMarkerClick(String id) {
    final reportsState = ref.read(reportsProvider);
    final allReports = [
      ...reportsState.dangerousReports,
      ...reportsState.recentReports
    ];
    
    // Find the report (using a loop to avoid StateError if not found)
    ReportModel? target;
    for (final r in allReports) {
      if (r.id == id) {
        target = r;
        break;
      }
    }

    if (target != null) {
      ref.read(mapControllerProvider.notifier).selectReport(target);
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportInfoSheet(
          report: target!,
          onViewDetail: () {
            Navigator.of(context).pop();
            context.push('${RouterPath.createReport}?id=${target!.id}');
          },
        ),
      );
    }
  }

  void _flyToUserLocation() {
    _evalJS('''
      if (navigator.geolocation && window.__smartspace_map) {
        navigator.geolocation.getCurrentPosition(function(pos) {
          window.__smartspace_map.flyTo({
            center: [pos.coords.longitude, pos.coords.latitude],
            zoom: 14,
            pitch: 45,
            duration: 1500
          });
        });
      }
    ''');
  }

  void _evalJS(String script) {
    final el = web.document.createElement('script') as web.HTMLScriptElement;
    el.text = script;
    web.document.body!.append(el);
    el.remove();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final reportsState = ref.watch(reportsProvider);
    final filteredReports = mapState.getFilteredReports(reportsState);

    // Update markers when data/filter changes
    ref.listen(mapControllerProvider, (prev, next) {
      if (_mapReady) {
        final reports = next.getFilteredReports(ref.read(reportsProvider));
        _updateMarkersJS(reports, ref.read(reportsProvider));
      }
    });
    ref.listen(reportsProvider, (prev, next) {
      if (_mapReady) {
        final reports =
            ref.read(mapControllerProvider).getFilteredReports(next);
        _updateMarkersJS(reports, next);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // MAPBOX GL JS MAP
          HtmlElementView.fromTagName(
            tagName: 'div',
            onElementCreated: (element) {
              final div = element as web.HTMLElement;
              div.id = 'mapbox-container';
              div.style.width = '100%';
              div.style.height = '100%';

              // Wait for container and Mapbox JS to be ready
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_mapboxJsLoaded && !_mapReady) {
                  _initMap();
                  Future.delayed(const Duration(milliseconds: 800), () {
                    _updateMarkersJS(filteredReports, reportsState);
                  });
                }
              });
            },
          ),

          // Loading indicator
          if (!_mapReady)
            const Center(child: CircularProgressIndicator()),

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
