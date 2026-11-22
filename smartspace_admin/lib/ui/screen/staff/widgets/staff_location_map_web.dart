// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

Widget buildStaffLocationMap({
  required BuildContext context,
  required double initialLat,
  required double initialLng,
  required void Function(double lat, double lng) onPicked,
}) {
  return _WebStaffLocationMap(
    initialLat: initialLat,
    initialLng: initialLng,
    onPicked: onPicked,
  );
}

class _WebStaffLocationMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onPicked;

  const _WebStaffLocationMap({
    required this.initialLat,
    required this.initialLng,
    required this.onPicked,
  });

  @override
  State<_WebStaffLocationMap> createState() => _WebStaffLocationMapState();
}

class _WebStaffLocationMapState extends State<_WebStaffLocationMap> {
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
    _viewId = 'staff-loc-picker-${identityHashCode(this)}';
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
  void didUpdateWidget(covariant _WebStaffLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLat != widget.initialLat ||
        oldWidget.initialLng != widget.initialLng) {
      _pushCenter(widget.initialLat, widget.initialLng);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _registerView() {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryHex =
        '#${(primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final config = jsonEncode({
      'channel': _viewId,
      'token': _token,
      'lat': widget.initialLat,
      'lng': widget.initialLng,
      'color': primaryHex,
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
      } else if (data['type'] == 'picked') {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          widget.onPicked(lat, lng);
        }
      }
    } catch (_) {}
  }

  void _pushCenter(double lat, double lng) {
    final win = _iframe?.contentWindow;
    if (!_ready || win == null) return;
    win.postMessage(
      jsonEncode({
        'channel': _viewId,
        'type': 'set_pin',
        'lat': lat,
        'lng': lng,
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
  style: 'mapbox://styles/mapbox/streets-v12',
  center: [cfg.lng, cfg.lat],
  zoom: 13
});
map.addControl(new mapboxgl.NavigationControl(), 'top-right');
var marker = new mapboxgl.Marker({ color: cfg.color, draggable: true })
  .setLngLat([cfg.lng, cfg.lat])
  .addTo(map);
marker.on('dragend', function() {
  var p = marker.getLngLat();
  post({ type: 'picked', lat: p.lat, lng: p.lng });
});
map.on('click', function(e) {
  marker.setLngLat(e.lngLat);
  post({ type: 'picked', lat: e.lngLat.lat, lng: e.lngLat.lng });
});
map.on('load', function() { post({ type: 'ready' }); });
window.addEventListener('message', function(ev) {
  if (typeof ev.data !== 'string') return;
  try {
    var msg = JSON.parse(ev.data);
    if (msg.channel !== cfg.channel) return;
    if (msg.type === 'set_pin') {
      marker.setLngLat([msg.lng, msg.lat]);
      map.flyTo({ center: [msg.lng, msg.lat], zoom: Math.max(map.getZoom(), 14) });
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
