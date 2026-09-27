// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';

/// Web map — uses Mapbox GL JS embedded in an iframe for reliable rendering.
Widget buildPlatformMap({
  required BuildContext context,
  required List<MapReportModel> reports,
  void Function(MapReportModel report)? onMarkerTap,
  VoidCallback? onMapTap,
}) {
  return _WebMapView(
    reports: reports,
    onMarkerTap: onMarkerTap,
    onMapTap: onMapTap,
  );
}

class _WebMapView extends StatefulWidget {
  final List<MapReportModel> reports;
  final void Function(MapReportModel report)? onMarkerTap;
  final VoidCallback? onMapTap;

  const _WebMapView({
    required this.reports,
    this.onMarkerTap,
    this.onMapTap,
  });

  @override
  State<_WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<_WebMapView> {
  late final String _viewId;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'admin-map-${identityHashCode(this)}';

    // Listen for marker clicks from the iframe
    html.window.onMessage.listen((html.MessageEvent event) {
      try {
        final data = jsonDecode(event.data.toString());
        if (data['type'] == 'marker_click') {
          final id = data['id'];
          final report = widget.reports.firstWhere((r) => r.id == id);
          widget.onMarkerTap?.call(report);
        } else if (data['type'] == 'map_click') {
          widget.onMapTap?.call();
        }
      } catch (e) {
        // Ignore non-json or unrelated messages
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_registered) {
      _registered = true;
      _registerView();
    }
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _buildMapHtml();
      return iframe;
    });
    setState(() {});
  }

  String _buildMapHtml() {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    // ponytail: always light map for admin readability — add style toggle in Phase 3 if needed
    const style = 'mapbox://styles/mapbox/streets-v12';

    final statusColors = {
      'pending': '#EF5350',
      'processing': '#FFCA28',
      'processed': '#66BB6A',
      'rejected': '#9E9E9E',
    };

    final reportsData = widget.reports
        .where((r) => r.latitude != 0 || r.longitude != 0)
        .map((r) => {
              'id': r.id,
              'title': r.title,
              'status': r.status,
              'lat': r.latitude,
              'lng': r.longitude,
              'address': r.address ?? '',
              'imageUrl': r.imageUrl ?? '',
              'color': statusColors[r.status] ?? '#9E9E9E',
            })
        .toList();

    final reportsJson = jsonEncode(reportsData);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.css"/>
<script src="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body, html { width: 100%; height: 100%; overflow: hidden; }
  #map { width: 100%; height: 100%; }

  .marker-pin {
    cursor: pointer;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.35));
  }
  .marker-pin .pin-body {
    width: 42px;
    height: 42px;
    border-radius: 50%;
    border-width: 3px;
    border-style: solid;
    background: #fff;
    overflow: hidden;
  }
  .marker-pin .pin-body img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
  .marker-pin .pin-body .fallback {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
  }
  .marker-pin .pin-tail {
    width: 0;
    height: 0;
    border-left: 8px solid transparent;
    border-right: 8px solid transparent;
    margin: -2px auto 0;
  }
</style>
</head>
<body>
<div id="map"></div>
<script>
  mapboxgl.accessToken = '$token';

  var map = new mapboxgl.Map({
    container: 'map',
    style: '$style',
    center: [106.6297, 10.8231],
    zoom: 12,
    pitch: 0,
    bearing: 0
  });

  map.addControl(new mapboxgl.NavigationControl(), 'top-right');
  map.addControl(new mapboxgl.GeolocateControl({
    positionOptions: { enableHighAccuracy: true },
    trackUserLocation: true,
    showUserHeading: true
  }), 'top-right');

  var reports = $reportsJson;
  var markerClicked = false;

  map.on('click', function() {
    if (markerClicked) { markerClicked = false; return; }
    window.parent.postMessage(JSON.stringify({ type: 'map_click' }), '*');
  });

  map.on('load', function() {
    reports.forEach(function(r) {
      // Create pin marker element
      var el = document.createElement('div');
      el.className = 'marker-pin';

      var body = document.createElement('div');
      body.className = 'pin-body';
      body.style.borderColor = r.color;

      if (r.imageUrl) {
        var img = document.createElement('img');
        img.src = r.imageUrl;
        img.onerror = function() {
          body.innerHTML = '<div class="fallback" style="color:' + r.color + '">📍</div>';
        };
        body.appendChild(img);
      } else {
        body.innerHTML = '<div class="fallback" style="color:' + r.color + '">📍</div>';
      }
      el.appendChild(body);

      var tail = document.createElement('div');
      tail.className = 'pin-tail';
      tail.style.borderTopColor = r.color;
      el.appendChild(tail);

      el.addEventListener('click', function(e) {
        e.stopPropagation();
        markerClicked = true;
        window.parent.postMessage(JSON.stringify({ type: 'marker_click', id: r.id }), '*');
      });

      new mapboxgl.Marker({ element: el, anchor: 'bottom' })
        .setLngLat([r.lng, r.lat])
        .addTo(map);
    });
  });
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      return const Center(child: CircularProgressIndicator());
    }
    return HtmlElementView(viewType: _viewId);
  }
}
