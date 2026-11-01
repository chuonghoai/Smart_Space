import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DensityMapLayer {
  static const String sourceId = 'admin-report-density-source';
  static const String fillLayerId = 'admin-report-density-fill-layer';
  static const String lineLayerId = 'admin-report-density-line-layer';

  final MapboxMap _map;
  bool _installed = false;

  DensityMapLayer({required MapboxMap map}) : _map = map;

  bool get isInstalled => _installed;

  Future<void> install({String? geojsonString}) async {
    final style = _map.style;
    final initialData = geojsonString ?? _emptyFeatureCollection();

    try {
      if (!await style.styleSourceExists(sourceId)) {
        await style.addSource(GeoJsonSource(
          id: sourceId,
          data: initialData,
        ));
      } else if (geojsonString != null) {
        await style.setStyleSourceProperty(sourceId, 'data', geojsonString);
      }

      if (!await style.styleLayerExists(fillLayerId)) {
        await style.addLayer(FillLayer(
          id: fillLayerId,
          sourceId: sourceId,
          fillColorExpression: ['get', 'color'],
          fillOpacity: 0.4,
        ));
      }

      if (!await style.styleLayerExists(lineLayerId)) {
        await style.addLayer(LineLayer(
          id: lineLayerId,
          sourceId: sourceId,
          lineColorExpression: ['get', 'color'],
          lineWidth: 1.5,
          lineOpacity: 0.8,
        ));
      }

      _installed = true;
    } catch (e) {
      debugPrint('[DensityMapLayer] Failed to install density layer: $e');
    }
  }

  Future<void> updateData(String? geojsonString) async {
    if (!_installed) {
      await install(geojsonString: geojsonString);
      return;
    }
    try {
      final style = _map.style;
      if (await style.styleSourceExists(sourceId)) {
        final data = geojsonString ?? _emptyFeatureCollection();
        await style.setStyleSourceProperty(sourceId, 'data', data);
      }
    } catch (e) {
      debugPrint('[DensityMapLayer] Failed to update density data: $e');
    }
  }

  Future<void> setVisible(bool visible) async {
    if (!_installed) return;
    try {
      final style = _map.style;
      final visibility = visible ? 'visible' : 'none';
      if (await style.styleLayerExists(fillLayerId)) {
        await style.setStyleLayerProperty(fillLayerId, 'visibility', visibility);
      }
      if (await style.styleLayerExists(lineLayerId)) {
        await style.setStyleLayerProperty(lineLayerId, 'visibility', visibility);
      }
    } catch (e) {
      debugPrint('[DensityMapLayer] Failed to toggle density visibility: $e');
    }
  }

  Future<void> remove() async {
    try {
      final style = _map.style;
      if (await style.styleLayerExists(lineLayerId)) {
        await style.removeStyleLayer(lineLayerId);
      }
      if (await style.styleLayerExists(fillLayerId)) {
        await style.removeStyleLayer(fillLayerId);
      }
      if (await style.styleSourceExists(sourceId)) {
        await style.removeStyleSource(sourceId);
      }
      _installed = false;
    } catch (e) {
      debugPrint('[DensityMapLayer] Failed to remove density layer: $e');
    }
  }

  static String _emptyFeatureCollection() => jsonEncode({
        'type': 'FeatureCollection',
        'features': [],
      });
}

