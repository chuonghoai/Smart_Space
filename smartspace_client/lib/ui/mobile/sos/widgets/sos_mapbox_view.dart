import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/providers/sos_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Bản đồ Mapbox hiển thị vị trí SOS trực tiếp (kèm đường di chuyển nếu có).
class SosMapboxView extends StatefulWidget {
  final SosAlertModel sos;
  final double? height;
  final VoidCallback? onExpand;

  const SosMapboxView({
    super.key,
    required this.sos,
    this.height = 240,
    this.onExpand,
  });

  @override
  State<SosMapboxView> createState() => _SosMapboxViewState();
}

class _SosMapboxViewState extends State<SosMapboxView> {
  static const _pointSourceId = 'sos-point-source';
  static const _haloLayerId = 'sos-point-halo-layer';
  static const _pinLayerId = 'sos-point-pin-layer';
  static const _trackSourceId = 'sos-track-source';
  static const _trackLayerId = 'sos-track-line-layer';

  MapboxMap? _mapboxMap;
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant SosMapboxView oldWidget) {
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
        pitch: 0.0,
        bearing: 0.0,
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final mapContent = Stack(
      children: [
        MapWidget(
          key: ValueKey('sos-mapbox-${isDark ? 'dark' : 'light'}'),
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
          child: Column(
            children: [
              _MapActionIcon(
                icon: Icons.my_location_rounded,
                tooltip: l10n.myLocation,
                onTap: _recenter,
              ),
              if (widget.onExpand != null) ...[
                const SizedBox(height: 8),
                _MapActionIcon(
                  icon: Icons.open_in_full_rounded,
                  tooltip: l10n.sosOpenMap,
                  onTap: widget.onExpand!,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.height == null) {
      return mapContent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: mapContent,
      ),
    );
  }
}

class _MapActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outline),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}

/// Mở bản đồ Mapbox toàn màn hình ngay trong app, tự cập nhật vị trí realtime qua provider.
Future<void> showSosMapboxFullscreen(
  BuildContext context, {
  required String title,
  required SosAlertModel initialSos,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SosMapboxFullscreenPage(title: title, initialSos: initialSos),
    ),
  );
}

class _SosMapboxFullscreenPage extends ConsumerWidget {
  final String title;
  final SosAlertModel initialSos;

  const _SosMapboxFullscreenPage({
    required this.title,
    required this.initialSos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveSos = ref.watch(watchedSosProvider(initialSos.id)).sos ?? initialSos;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SosMapboxView(sos: liveSos, height: null),
    );
  }
}
