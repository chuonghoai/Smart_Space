import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';

Widget buildSosMapboxMap({
  required BuildContext context,
  required SosAlertModel sos,
}) {
  return _MobileSosMapboxMap(sos: sos);
}

class _MobileSosMapboxMap extends StatefulWidget {
  final SosAlertModel sos;

  const _MobileSosMapboxMap({required this.sos});

  @override
  State<_MobileSosMapboxMap> createState() => _MobileSosMapboxMapState();
}

class _MobileSosMapboxMapState extends State<_MobileSosMapboxMap> {
  static const _pointSourceId = 'admin-sos-point-source';
  static const _haloLayerId = 'admin-sos-point-halo-layer';
  static const _pinLayerId = 'admin-sos-point-pin-layer';
  static const _trackSourceId = 'admin-sos-track-source';
  static const _trackLayerId = 'admin-sos-track-line-layer';

  MapboxMap? _mapboxMap;
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant _MobileSosMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = oldWidget.sos.latitude != widget.sos.latitude ||
        oldWidget.sos.longitude != widget.sos.longitude;
    final trackChanged = oldWidget.sos.track.length != widget.sos.track.length;
    if (moved || trackChanged) {
      _syncData(flyToLatest: moved);
    }
  }

  String _pointGeoJson(SosAlertModel sos) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [sos.longitude, sos.latitude],
            },
            'properties': <String, Object?>{},
          },
        ],
      });

  String _trackGeoJson(SosAlertModel sos) {
    final coords = sos.track.length > 1
        ? sos.track.reversed.map((p) => [p.longitude, p.latitude]).toList()
        : <List<double>>[];
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': coords.length > 1
          ? [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': coords,
                },
                'properties': <String, Object?>{},
              },
            ]
          : <Object>[],
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(widget.sos.longitude, widget.sos.latitude)),
        zoom: 16.0,
      ),
    );
  }

  void _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    final cs = Theme.of(context).colorScheme;
    final style = map.style;

    if (!await style.styleSourceExists(_trackSourceId)) {
      await style.addSource(GeoJsonSource(id: _trackSourceId, data: _trackGeoJson(widget.sos)));
    }
    if (!await style.styleLayerExists(_trackLayerId)) {
      await style.addLayer(
        LineLayer(
          id: _trackLayerId,
          sourceId: _trackSourceId,
          lineColor: cs.error.toARGB32(),
          lineWidth: 3.5,
          lineOpacity: 0.85,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    if (!await style.styleSourceExists(_pointSourceId)) {
      await style.addSource(GeoJsonSource(id: _pointSourceId, data: _pointGeoJson(widget.sos)));
    }
    if (!await style.styleLayerExists(_haloLayerId)) {
      await style.addLayer(
        CircleLayer(
          id: _haloLayerId,
          sourceId: _pointSourceId,
          circleRadius: 22.0,
          circleColor: cs.error.toARGB32(),
          circleOpacity: 0.22,
        ),
      );
    }
    if (!await style.styleLayerExists(_pinLayerId)) {
      await style.addLayer(
        CircleLayer(
          id: _pinLayerId,
          sourceId: _pointSourceId,
          circleRadius: 9.0,
          circleColor: cs.error.toARGB32(),
          circleStrokeWidth: 3.0,
          circleStrokeColor: cs.surface.toARGB32(),
        ),
      );
    }
    _styleReady = true;
  }

  Future<void> _syncData({required bool flyToLatest}) async {
    final map = _mapboxMap;
    if (map == null || !_styleReady) return;
    await map.style.setStyleSourceProperty(_pointSourceId, 'data', _pointGeoJson(widget.sos));
    await map.style.setStyleSourceProperty(_trackSourceId, 'data', _trackGeoJson(widget.sos));
    if (flyToLatest) {
      await _recenter();
    }
  }

  Future<void> _recenter() async {
    final map = _mapboxMap;
    if (map == null) return;
    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(widget.sos.longitude, widget.sos.latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        MapWidget(
          key: ValueKey('admin-sos-mapbox-${isDark ? 'dark' : 'light'}'),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          styleUri: isDark ? MapboxStyles.DARK : MapboxStyles.STANDARD,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: cs.outline),
            ),
            child: IconButton(
              onPressed: _recenter,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(Icons.my_location_rounded, size: 20, color: cs.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
