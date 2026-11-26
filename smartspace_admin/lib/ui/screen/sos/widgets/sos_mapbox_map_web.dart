import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

Widget buildSosMapboxMap({
  required BuildContext context,
  required SosAlertModel sos,
}) {
  return _WebSosMapboxMap(sos: sos);
}

class _WebSosMapboxMap extends StatefulWidget {
  final SosAlertModel sos;

  const _WebSosMapboxMap({required this.sos});

  @override
  State<_WebSosMapboxMap> createState() => _WebSosMapboxMapState();
}

class _WebSosMapboxMapState extends State<_WebSosMapboxMap> {
  late final String _viewId;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _sub;
  bool _registered = false;
  bool _ready = false;
  late String _token;

  @override
  void initState() {
    super.initState();
    _token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    _viewId = 'admin-sos-map-${identityHashCode(this)}';
    _sub = html.window.onMessage.listen(_onMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_registered && _token.isNotEmpty) {
      _registered = true;
      _registerView();
    }
  }

  @override
  void didUpdateWidget(covariant _WebSosMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = oldWidget.sos.latitude != widget.sos.latitude ||
        oldWidget.sos.longitude != widget.sos.longitude;
    final trackChanged = oldWidget.sos.track.length != widget.sos.track.length;
    if (moved || trackChanged) {
      _pushUpdate(flyTo: moved);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<List<double>> _trackCoords(SosAlertModel sos) {
    if (sos.track.length <= 1) return const [];
    return sos.track.reversed.map((p) => [p.longitude, p.latitude]).toList();
  }

  String _toHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  void _registerView() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final config = jsonEncode({
      'channel': _viewId,
      'token': _token,
      'style': isDark ? 'mapbox://styles/mapbox/dark-v11' : 'mapbox://styles/mapbox/streets-v12',
      'lat': widget.sos.latitude,
      'lng': widget.sos.longitude,
      'track': _trackCoords(widget.sos),
      'errorColor': _toHex(cs.error),
      'surfaceColor': _toHex(cs.surface),
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _html(config);
      _iframe = iframe;
      return iframe;
    });
  }

  void _onMessage(html.MessageEvent event) {
    final raw = event.data;
    if (raw is! String || !mounted) return;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> || data['channel'] != _viewId) return;
      if (data['type'] == 'ready') {
        _ready = true;
      }
    } catch (_) {}
  }

  void _pushUpdate({required bool flyTo}) {
    final win = _iframe?.contentWindow;
    if (!_ready || win == null) return;
    win.postMessage(
      jsonEncode({
        'channel': _viewId,
        'type': 'update_sos',
        'lat': widget.sos.latitude,
        'lng': widget.sos.longitude,
        'track': _trackCoords(widget.sos),
        'flyTo': flyTo,
      }),
      '*',
    );
  }

  String _html(String configJson) => '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.css"/>
<script src="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body, #map { width: 100%; height: 100%; overflow: hidden; }
</style>
</head>
<body>
<div id="map"></div>
<script>
var cfg = $configJson;
function post(m) { m.channel = cfg.channel; window.parent.postMessage(JSON.stringify(m), '*'); }
mapboxgl.accessToken = cfg.token;
var map = new mapboxgl.Map({
  container: 'map',
  style: cfg.style,
  center: [cfg.lng, cfg.lat],
  zoom: 16
});
map.addControl(new mapboxgl.NavigationControl(), 'top-right');

function pointGeoJson(lng, lat) {
  return {
    type: 'FeatureCollection',
    features: [{ type: 'Feature', geometry: { type: 'Point', coordinates: [lng, lat] }, properties: {} }]
  };
}
function trackGeoJson(coords) {
  return {
    type: 'FeatureCollection',
    features: coords && coords.length > 1
      ? [{ type: 'Feature', geometry: { type: 'LineString', coordinates: coords }, properties: {} }]
      : []
  };
}

map.on('load', function() {
  map.addSource('sos-track', { type: 'geojson', data: trackGeoJson(cfg.track) });
  map.addLayer({
    id: 'sos-track-line',
    type: 'line',
    source: 'sos-track',
    layout: { 'line-cap': 'round', 'line-join': 'round' },
    paint: { 'line-color': cfg.errorColor, 'line-width': 3.5, 'line-opacity': 0.85 }
  });
  map.addSource('sos-point', { type: 'geojson', data: pointGeoJson(cfg.lng, cfg.lat) });
  map.addLayer({
    id: 'sos-point-halo',
    type: 'circle',
    source: 'sos-point',
    paint: { 'circle-radius': 22, 'circle-color': cfg.errorColor, 'circle-opacity': 0.22 }
  });
  map.addLayer({
    id: 'sos-point-pin',
    type: 'circle',
    source: 'sos-point',
    paint: {
      'circle-radius': 9,
      'circle-color': cfg.errorColor,
      'circle-stroke-width': 3,
      'circle-stroke-color': cfg.surfaceColor
    }
  });
  post({ type: 'ready' });
});

window.addEventListener('message', function(ev) {
  if (typeof ev.data !== 'string') return;
  try {
    var msg = JSON.parse(ev.data);
    if (msg.channel !== cfg.channel) return;
    if (msg.type === 'update_sos') {
      var pt = map.getSource('sos-point');
      var tr = map.getSource('sos-track');
      if (pt) pt.setData(pointGeoJson(msg.lng, msg.lat));
      if (tr) tr.setData(trackGeoJson(msg.track));
      if (msg.flyTo) {
        map.flyTo({ center: [msg.lng, msg.lat], zoom: Math.max(map.getZoom(), 15) });
      }
    }
  } catch (e) {}
});
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.staffLocationWebNoToken,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return HtmlElementView(viewType: _viewId);
  }
}
