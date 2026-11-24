import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';

class StaffBaseMapLayer {
  static const String sourceId = 'admin-staff-stations-source';
  static const String circleLayerId = 'admin-staff-stations-circle-layer';
  static const String labelLayerId = 'admin-staff-stations-label-layer';

  final MapboxMap _map;
  bool _installed = false;

  StaffBaseMapLayer({required MapboxMap map}) : _map = map;

  bool get isInstalled => _installed;

  Future<void> install({
    required List<StaffModel> staffs,
    required Color primaryColor,
    required Color onPrimaryColor,
    bool visible = true,
  }) async {
    final style = _map.style;
    final data = _buildGeoJson(staffs);

    try {
      if (!await style.styleSourceExists(sourceId)) {
        await style.addSource(GeoJsonSource(id: sourceId, data: data));
      } else {
        await style.setStyleSourceProperty(sourceId, 'data', data);
      }

      if (!await style.styleLayerExists(circleLayerId)) {
        await style.addLayer(
          CircleLayer(
            id: circleLayerId,
            sourceId: sourceId,
            circleRadius: 11.0,
            circleColor: primaryColor.toARGB32(),
            circleStrokeWidth: 2.5,
            circleStrokeColor: onPrimaryColor.toARGB32(),
          ),
        );
      }

      if (!await style.styleLayerExists(labelLayerId)) {
        await style.addLayer(
          SymbolLayer(
            id: labelLayerId,
            sourceId: sourceId,
            textFieldExpression: ['get', 'label'],
            textSize: 11.5,
            textOffset: [0.0, 1.4],
            textAnchor: TextAnchor.TOP,
            textColor: primaryColor.toARGB32(),
            textHaloColor: onPrimaryColor.toARGB32(),
            textHaloWidth: 1.5,
          ),
        );
      }

      _installed = true;
      await setVisible(visible);
    } catch (e) {
      debugPrint('[StaffBaseMapLayer] Failed to install layer: $e');
    }
  }

  Future<void> updateData(List<StaffModel> staffs) async {
    if (!_installed) return;
    try {
      final style = _map.style;
      if (await style.styleSourceExists(sourceId)) {
        await style.setStyleSourceProperty(
          sourceId,
          'data',
          _buildGeoJson(staffs),
        );
      }
    } catch (e) {
      debugPrint('[StaffBaseMapLayer] Failed to update data: $e');
    }
  }

  Future<void> setVisible(bool visible) async {
    if (!_installed) return;
    try {
      final style = _map.style;
      final vis = visible ? 'visible' : 'none';
      if (await style.styleLayerExists(circleLayerId)) {
        await style.setStyleLayerProperty(circleLayerId, 'visibility', vis);
      }
      if (await style.styleLayerExists(labelLayerId)) {
        await style.setStyleLayerProperty(labelLayerId, 'visibility', vis);
      }
    } catch (e) {
      debugPrint('[StaffBaseMapLayer] Failed to toggle visibility: $e');
    }
  }

  Future<String?> handleTap(MapContentGestureContext gestureContext) async {
    if (!_installed) return null;
    try {
      final features = await _map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(
          gestureContext.touchPosition,
        ),
        RenderedQueryOptions(layerIds: [circleLayerId, labelLayerId]),
      );
      for (final f in features) {
        final props = f?.queriedFeature.feature['properties'];
        if (props is Map && props['id'] != null) {
          return props['id'].toString();
        }
      }
    } catch (e) {
      debugPrint('[StaffBaseMapLayer] Failed to query tap: $e');
    }
    return null;
  }

  Future<void> remove() async {
    try {
      final style = _map.style;
      if (await style.styleLayerExists(labelLayerId)) {
        await style.removeStyleLayer(labelLayerId);
      }
      if (await style.styleLayerExists(circleLayerId)) {
        await style.removeStyleLayer(circleLayerId);
      }
      if (await style.styleSourceExists(sourceId)) {
        await style.removeStyleSource(sourceId);
      }
      _installed = false;
    } catch (e) {
      debugPrint('[StaffBaseMapLayer] Failed to remove layer: $e');
    }
  }

  static String _buildGeoJson(List<StaffModel> staffs) {
    final features = <Map<String, dynamic>>[];
    for (final s in staffs) {
      if (!s.hasBaseLocation) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [s.baseLongitude, s.baseLatitude],
        },
        'properties': {
          'id': s.id,
          'label': '${s.fullName} (${s.processingCount})',
        },
      });
    }
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });
  }
}
