// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/map/cluster/cluster_layer_colors.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';
import 'platform_map_controller.dart';
import 'widgets/map_cluster_colors.dart';

/// Web map — Mapbox GL JS trong iframe, report gom cụm (cluster) + mật độ H3.
///
/// Giao tiếp 2 chiều qua `postMessage`, mọi message mang `channel` riêng của view:
/// - iframe → Flutter: `ready`, `viewport`, `marker_click`, `cluster_list`, `map_click`
/// - Flutter → iframe: `set_reports`, `set_density`, `fly_to`, `get_viewport`
Widget buildPlatformMap({
  required BuildContext context,
  required List<MapReportModel> reports,
  required void Function(MapReportModel report) onMarkerTap,
  required void Function(List<MapReportModel> reports) onClusterTap,
  required void Function(MapBounds bounds) onViewportChanged,
  VoidCallback? onMapTap,
  MapFocusTarget? initialFocus,
  void Function(PlatformMapController controller)? onMapControllerCreated,
}) {
  return _WebMapView(
    reports: reports,
    onMarkerTap: onMarkerTap,
    onClusterTap: onClusterTap,
    onViewportChanged: onViewportChanged,
    onMapTap: onMapTap,
    initialFocus: initialFocus,
    onMapControllerCreated: onMapControllerCreated,
  );
}

class _WebMapView extends ConsumerStatefulWidget {
  final List<MapReportModel> reports;
  final void Function(MapReportModel report) onMarkerTap;
  final void Function(List<MapReportModel> reports) onClusterTap;
  final void Function(MapBounds bounds) onViewportChanged;
  final VoidCallback? onMapTap;
  final MapFocusTarget? initialFocus;
  final void Function(PlatformMapController controller)? onMapControllerCreated;

  const _WebMapView({
    required this.reports,
    required this.onMarkerTap,
    required this.onClusterTap,
    required this.onViewportChanged,
    this.onMapTap,
    this.initialFocus,
    this.onMapControllerCreated,
  });

  @override
  ConsumerState<_WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends ConsumerState<_WebMapView>
    implements PlatformMapController {
  late final String _viewId;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messageSub;
  bool _registered = false;
  bool _ready = false;
  String? _lastPayload;
  bool _forceNextViewport = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'admin-map-${identityHashCode(this)}';
    _messageSub = html.window.onMessage.listen(_onMessage);
    widget.onMapControllerCreated?.call(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_registered) {
      _registered = true;
      _registerView();
    }
    // Theme có thể đã đổi → gửi lại màu
    _pushReports();
    _pushDensity();
  }

  @override
  void didUpdateWidget(covariant _WebMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reports != widget.reports) _pushReports();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _registerView() {
    final focus = widget.initialFocus;
    final config = jsonEncode({
      'center': focus != null ? [focus.longitude, focus.latitude] : [106.6297, 10.8231],
      'zoom': focus != null ? MapFocusTarget.zoom : 12,
      'channel': _viewId,
      'token': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
      'style': 'mapbox://styles/mapbox/streets-v12',
      'clusterRadius': 50,
      'clusterMaxZoom': 16,
      'reduceMotion': MediaQuery.of(context).disableAnimations,
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _buildMapHtml(config);
      _iframe = iframe;
      return iframe;
    });
    setState(() {});
  }

  void _onMessage(html.MessageEvent event) {
    final raw = event.data;
    if (raw is! String || !mounted) return;

    final Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } catch (_) {
      return;
    }
    if (message['channel'] != _viewId) return;

    switch (message['type']) {
      case 'ready':
        _ready = true;
        _lastPayload = null;
        _pushReports();
        _pushDensity();
      case 'viewport':
        final bounds = _boundsOf(message);
        if (bounds != null) {
          final force = _forceNextViewport;
          _forceNextViewport = false;
          widget.onViewportChanged(bounds);
          final zoom = (message['zoom'] as num?)?.toDouble() ?? 14.0;
          ref.read(adminReportDensityProvider.notifier).loadForViewport(bounds, zoom, force: force);
        }
      case 'marker_click':
        final report = widget.reports.where((r) => r.id == message['id']).firstOrNull;
        if (report != null) widget.onMarkerTap(report);
      case 'cluster_list':
        final ids = {
          for (final id in (message['ids'] as List? ?? const []))
            if (id is String) id,
        };
        final reports = widget.reports.where((r) => ids.contains(r.id)).toList();
        if (reports.isNotEmpty) widget.onClusterTap(reports);
      case 'map_click':
        widget.onMapTap?.call();
    }
  }

  MapBounds? _boundsOf(Map<String, dynamic> message) {
    final values = [
      message['minLat'],
      message['maxLat'],
      message['minLng'],
      message['maxLng'],
    ];
    if (values.any((v) => v is! num)) return null;
    final bounds = MapBounds(
      minLat: (values[0] as num).toDouble(),
      maxLat: (values[1] as num).toDouble(),
      minLng: (values[2] as num).toDouble(),
      maxLng: (values[3] as num).toDouble(),
    );
    return bounds.minLat <= bounds.maxLat && bounds.minLng <= bounds.maxLng ? bounds : null;
  }

  void _pushReports() {
    final window = _iframe?.contentWindow;
    if (!_ready || window == null || !mounted) return;

    final colors = adminClusterColors(context);
    final payload = jsonEncode({
      'channel': _viewId,
      'type': 'set_reports',
      'colors': {
        'normal': ClusterLayerColors.toRgba(colors.normal),
        'onNormal': ClusterLayerColors.toRgba(colors.onNormal),
        'alert': ClusterLayerColors.toRgba(colors.alert),
        'onAlert': ClusterLayerColors.toRgba(colors.onAlert),
        'stroke': ClusterLayerColors.toRgba(colors.stroke),
      },
      'reports': [
        for (final r in widget.reports)
          if (r.latitude != 0 || r.longitude != 0)
            {
              'id': r.id,
              'lat': r.latitude,
              'lng': r.longitude,
              'imageUrl': r.imageUrl ?? '',
              'isAlert': r.isPending,
              'color': ClusterLayerColors.toRgba(reportStatusColor(context, r.status)),
            },
      ],
    });
    if (payload == _lastPayload) return;
    _lastPayload = payload;
    window.postMessage(payload, '*');
  }

  void _pushDensity() {
    final window = _iframe?.contentWindow;
    if (!_ready || window == null || !mounted) return;
    final density = ref.read(adminReportDensityProvider);
    window.postMessage(
      jsonEncode({
        'channel': _viewId,
        'type': 'set_density',
        'geojson': density.geojsonString,
        'visible': density.isEnabled,
      }),
      '*',
    );
  }

  @override
  Future<void> flyToUserLocation() async {
    final pos = await locationService.getCurrentPosition();
    if (pos == null) return;
    final window = _iframe?.contentWindow;
    if (!_ready || window == null) return;
    window.postMessage(
      jsonEncode({
        'channel': _viewId,
        'type': 'fly_to',
        'lng': pos.longitude,
        'lat': pos.latitude,
        'zoom': 15.0,
      }),
      '*',
    );
  }

  @override
  Future<void> refreshViewport() async {
    final window = _iframe?.contentWindow;
    if (!_ready || window == null) return;
    window.postMessage(
      jsonEncode({
        'channel': _viewId,
        'type': 'get_viewport',
      }),
      '*',
    );
  }

  String _buildMapHtml(String configJson) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.css"/>
<script src="https://api.mapbox.com/mapbox-gl-js/v3.9.4/mapbox-gl.js"></script>
<style>$_mapCss</style>
</head>
<body>
<div id="map"></div>
<script>var config = $configJson;</script>
<script>$_mapScript</script>
</body>
</html>
''';
  }

  static const String _mapCss = r'''
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body, html { width: 100%; height: 100%; overflow: hidden; }
  #map { width: 100%; height: 100%; }

  .marker-pin {
    cursor: pointer;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.35));
  }
  .marker-pin.alert { transform-origin: bottom center; }
  .marker-pin.alert .pin-body { width: 50px; height: 50px; }
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
  }
  .marker-pin .pin-body .fallback span {
    width: 14px;
    height: 14px;
    border-radius: 50%;
  }
  .marker-pin .pin-tail {
    width: 0;
    height: 0;
    border-left: 8px solid transparent;
    border-right: 8px solid transparent;
    margin: -2px auto 0;
  }
''';

  static const String _mapScript = r'''
  var CHANNEL = config.channel;
  var CLUSTER_MAX_ZOOM = config.clusterMaxZoom;
  var reduceMotion = config.reduceMotion ||
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function post(msg) {
    msg.channel = CHANNEL;
    window.parent.postMessage(JSON.stringify(msg), '*');
  }

  mapboxgl.accessToken = config.token;
  var map = new mapboxgl.Map({
    container: 'map',
    style: config.style,
    center: config.center,
    zoom: config.zoom,
    pitch: 0,
    bearing: 0
  });

  map.addControl(new mapboxgl.NavigationControl(), 'top-right');

  var reportsById = {};
  var colors = null;
  var markers = {};
  var markersOnScreen = {};
  var markerClicked = false;

  function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

  function postViewport() {
    var b = map.getBounds();
    post({
      type: 'viewport',
      minLat: clamp(b.getSouth(), -90, 90),
      maxLat: clamp(b.getNorth(), -90, 90),
      minLng: clamp(b.getWest(), -180, 180),
      maxLng: clamp(b.getEast(), -180, 180),
      zoom: map.getZoom()
    });
  }

  function markerKey(r) { return r.color + '|' + r.imageUrl + '|' + r.isAlert; }

  function createMarker(r) {
    var el = document.createElement('div');
    el.className = 'marker-pin' + (r.isAlert ? ' alert' : '');

    var body = document.createElement('div');
    body.className = 'pin-body';
    body.style.borderColor = r.color;

    function fallback() {
      body.innerHTML = '';
      var wrap = document.createElement('div');
      wrap.className = 'fallback';
      var dot = document.createElement('span');
      dot.style.background = r.color;
      wrap.appendChild(dot);
      body.appendChild(wrap);
    }

    if (r.imageUrl && r.imageUrl.length > 0) {
      var img = document.createElement('img');
      img.src = r.imageUrl;
      img.alt = '';
      img.onerror = fallback;
      body.appendChild(img);
    } else {
      fallback();
    }

    var tail = document.createElement('div');
    tail.className = 'pin-tail';
    tail.style.borderTop = '10px solid ' + r.color;

    el.appendChild(body);
    el.appendChild(tail);

    el.addEventListener('click', function(e) {
      e.stopPropagation();
      markerClicked = true;
      post({ type: 'marker_click', id: r.id });
    });

    var marker = new mapboxgl.Marker({ element: el, anchor: 'bottom' })
      .setLngLat([r.lng, r.lat]);
    marker._smartSpaceKey = markerKey(r);
    return marker;
  }

  function updateMarkers() {
    if (!map.getSource('reports')) return;
    var features;
    try {
      features = map.querySourceFeatures('reports');
    } catch (_) { return; }

    var next = {};
    for (var i = 0; i < features.length; i++) {
      var f = features[i];
      if (f.properties && f.properties.point_count) continue;
      var id = f.properties.id;
      var r = reportsById[id];
      if (!r) continue;

      next[id] = true;
      var current = markers[id];
      var key = markerKey(r);
      if (!current || current._smartSpaceKey !== key) {
        if (current) current.remove();
        markers[id] = createMarker(r);
      }
      if (!markersOnScreen[id]) {
        markers[id].addTo(map);
      }
    }

    Object.keys(markersOnScreen).forEach(function(id) {
      if (!next[id]) markersOnScreen[id].remove();
    });
    markersOnScreen = next;
  }

  function applyColors() {
    if (!colors || !map.getLayer('clusters')) return;
    var hasAlert = ['>', ['get', 'alertCount'], 0];
    map.setPaintProperty('clusters', 'circle-color', ['case', hasAlert, colors.alert, colors.normal]);
    map.setPaintProperty('clusters', 'circle-stroke-color', colors.stroke);
    map.setPaintProperty('cluster-count', 'text-color', ['case', hasAlert, colors.onAlert, colors.onNormal]);
  }

  function applyReports(msg) {
    colors = msg.colors;
    reportsById = {};
    msg.reports.forEach(function(r) { reportsById[r.id] = r; });

    Object.keys(markers).forEach(function(id) {
      if (!reportsById[id]) {
        markers[id].remove();
        delete markers[id];
        delete markersOnScreen[id];
      }
    });

    applyColors();
    var source = map.getSource('reports');
    if (!source) return;
    source.setData({
      type: 'FeatureCollection',
      features: msg.reports.map(function(r) {
        return {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [r.lng, r.lat] },
          properties: { id: r.id, isAlert: r.isAlert }
        };
      })
    });
  }

  function applyDensity(geojson, visible) {
    var source = map.getSource('density');
    if (!source) return;
    if (geojson) {
      try {
        var parsed = typeof geojson === 'string' ? JSON.parse(geojson) : geojson;
        source.setData(parsed);
      } catch (err) {
        console.error('[WebMap] Error updating density source', err);
      }
    }
    var vis = visible ? 'visible' : 'none';
    if (map.getLayer('density-fill')) map.setLayoutProperty('density-fill', 'visibility', vis);
    if (map.getLayer('density-line')) map.setLayoutProperty('density-line', 'visibility', vis);
  }

  window.addEventListener('message', function(e) {
    var msg;
    try { msg = JSON.parse(e.data); } catch (_) { return; }
    if (!msg || msg.channel !== CHANNEL) return;
    if (msg.type === 'set_reports') applyReports(msg);
    if (msg.type === 'set_density') applyDensity(msg.geojson, msg.visible);
    if (msg.type === 'fly_to') {
      map.flyTo({
        center: [msg.lng, msg.lat],
        zoom: msg.zoom || 15,
        essential: true
      });
    }
    if (msg.type === 'get_viewport') {
      postViewport();
    }
  });

  map.on('load', function() {
    map.addSource('density', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] }
    });

    map.addLayer({
      id: 'density-fill',
      type: 'fill',
      source: 'density',
      layout: { 'visibility': 'none' },
      paint: {
        'fill-color': ['get', 'color'],
        'fill-opacity': 0.4
      }
    });

    map.addLayer({
      id: 'density-line',
      type: 'line',
      source: 'density',
      layout: { 'visibility': 'none' },
      paint: {
        'line-color': ['get', 'color'],
        'line-width': 1.5,
        'line-opacity': 0.8
      }
    });

    map.addSource('reports', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
      cluster: true,
      clusterRadius: config.clusterRadius,
      clusterMaxZoom: CLUSTER_MAX_ZOOM,
      clusterProperties: { alertCount: ['+', ['case', ['get', 'isAlert'], 1, 0]] }
    });

    map.addLayer({
      id: 'clusters',
      type: 'circle',
      source: 'reports',
      filter: ['has', 'point_count'],
      paint: {
        'circle-color': '#00796B',
        'circle-radius': ['step', ['get', 'point_count'], 18, 10, 22, 50, 28],
        'circle-stroke-width': 3,
        'circle-stroke-color': '#FFFFFF'
      }
    });

    map.addLayer({
      id: 'cluster-count',
      type: 'symbol',
      source: 'reports',
      filter: ['has', 'point_count'],
      layout: {
        'text-field': ['get', 'point_count_abbreviated'],
        'text-font': ['DIN Pro Medium', 'Arial Unicode MS Regular'],
        'text-size': 13,
        'text-allow-overlap': true
      },
      paint: { 'text-color': '#FFFFFF' }
    });

    map.on('click', 'clusters', function(e) {
      var feature = e.features[0];
      var clusterId = feature.properties.cluster_id;
      var source = map.getSource('reports');
      source.getClusterExpansionZoom(clusterId, function(err, zoom) {
        if (err) return;
        if (zoom <= CLUSTER_MAX_ZOOM) {
          map.easeTo({
            center: feature.geometry.coordinates,
            zoom: zoom,
            duration: reduceMotion ? 0 : 500
          });
          return;
        }
        source.getClusterLeaves(clusterId, Infinity, 0, function(err2, leaves) {
          if (err2) return;
          post({ type: 'cluster_list', ids: leaves.map(function(l) { return l.properties.id; }) });
        });
      });
    });

    map.on('mouseenter', 'clusters', function() { map.getCanvas().style.cursor = 'pointer'; });
    map.on('mouseleave', 'clusters', function() { map.getCanvas().style.cursor = ''; });

    map.on('render', function() {
      if (map.getSource('reports') && map.isSourceLoaded('reports')) updateMarkers();
    });
    map.on('moveend', postViewport);

    post({ type: 'ready' });
    postViewport();
  });

  map.on('click', function(e) {
    if (markerClicked) { markerClicked = false; return; }
    if (map.getLayer('clusters') &&
        map.queryRenderedFeatures(e.point, { layers: ['clusters'] }).length) return;
    post({ type: 'map_click' });
  });
''';

  @override
  Widget build(BuildContext context) {
    // Listen to Density GeoJSON updates
    ref.listen(adminReportDensityProvider.select((s) => s.geojsonString), (_, _) {
      _pushDensity();
    });

    // Listen to Density Toggle on/off
    ref.listen(adminReportDensityProvider.select((s) => s.isEnabled), (_, _) {
      _pushDensity();
    });

    if (!_registered) {
      return const Center(child: CircularProgressIndicator());
    }
    return HtmlElementView(viewType: _viewId);
  }
}
