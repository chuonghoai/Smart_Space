import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Widget buildStaffLocationMap({
  required BuildContext context,
  required double initialLat,
  required double initialLng,
  required void Function(double lat, double lng) onPicked,
}) {
  return _MobileStaffLocationMap(
    initialLat: initialLat,
    initialLng: initialLng,
    onPicked: onPicked,
  );
}

class _MobileStaffLocationMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onPicked;

  const _MobileStaffLocationMap({
    required this.initialLat,
    required this.initialLng,
    required this.onPicked,
  });

  @override
  State<_MobileStaffLocationMap> createState() =>
      _MobileStaffLocationMapState();
}

class _MobileStaffLocationMapState extends State<_MobileStaffLocationMap> {
  static const _sourceId = 'staff-base-pin-source';
  static const _layerId = 'staff-base-pin-layer';

  MapboxMap? _mapboxMap;
  bool _styleReady = false;
  late double _lat;
  late double _lng;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
  }

  @override
  void didUpdateWidget(covariant _MobileStaffLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLat != widget.initialLat ||
        oldWidget.initialLng != widget.initialLng) {
      _lat = widget.initialLat;
      _lng = widget.initialLng;
      _updatePin();
    }
  }

  String _geoJson(double lat, double lng) => jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [lng, lat],
            },
            'properties': <String, Object?>{},
          },
        ],
      });

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    mapboxMap.addInteraction(
      TapInteraction.onMap((gestureContext) {
        final coords = gestureContext.point.coordinates;
        final lat = coords.lat.toDouble();
        final lng = coords.lng.toDouble();
        setState(() {
          _lat = lat;
          _lng = lng;
        });
        _updatePin();
        widget.onPicked(lat, lng);
      }, stopPropagation: false),
    );
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(_lng, _lat)),
        zoom: 13.0,
      ),
    );
  }

  void _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    final cs = Theme.of(context).colorScheme;
    final style = map.style;
    if (!await style.styleSourceExists(_sourceId)) {
      await style.addSource(GeoJsonSource(
        id: _sourceId,
        data: _geoJson(_lat, _lng),
      ));
    }
    if (!await style.styleLayerExists(_layerId)) {
      await style.addLayer(CircleLayer(
        id: _layerId,
        sourceId: _sourceId,
        circleRadius: 10.0,
        circleColor: cs.primary.toARGB32(),
        circleStrokeWidth: 3.0,
        circleStrokeColor: cs.surface.toARGB32(),
      ));
    }
    _styleReady = true;
  }

  Future<void> _updatePin() async {
    final map = _mapboxMap;
    if (map == null || !_styleReady) return;
    await map.style.setStyleSourceProperty(
      _sourceId,
      'data',
      _geoJson(_lat, _lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      styleUri: MapboxStyles.STANDARD,
    );
  }
}
