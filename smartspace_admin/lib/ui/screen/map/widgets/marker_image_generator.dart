import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Utility class to generate custom marker images for Mapbox.
/// Adapted from smartspace_client — markers colored by report status.
class MarkerImageGenerator {
  final Map<String, Uint8List> _cache = {};

  static const double _markerWidth = 240;
  static const double _markerHeight = 300;
  static const double _borderWidth = 8;
  static const double _shadowBlur = 10;

  /// Generate a pin-drop marker image with the report photo inside.
  ///
  /// [borderColor] — semantic color based on status.
  /// [showRadarRings] — true for pending/urgent reports.
  Future<Uint8List> generateMarkerImage({
    required String imageUrl,
    required Color borderColor,
    required String cacheKey,
    bool showRadarRings = false,
  }) async {
    final fullKey = '${cacheKey}_${borderColor.toARGB32()}_$showRadarRings';
    if (_cache.containsKey(fullKey)) return _cache[fullKey]!;

    ui.Image? reportImage;
    if (imageUrl.isNotEmpty) {
      try {
        reportImage = await _loadImageFromUrl(imageUrl);
      } catch (e) {
        debugPrint('[MarkerGen] Failed to load image: $imageUrl — $e');
      }
    }

    final Uint8List bytes;
    if (reportImage != null) {
      bytes = await _renderMarkerWithImage(reportImage, borderColor, showRadarRings);
      reportImage.dispose();
    } else {
      bytes = await _renderFallbackMarker(borderColor, showRadarRings);
    }

    _cache[fullKey] = bytes;
    return bytes;
  }

  Future<ui.Image> _loadImageFromUrl(String url) async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 5));
      final bytesBuilder = BytesBuilder();
      await for (final chunk in response) {
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.toBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _markerWidth.toInt(),
        targetHeight: _markerWidth.toInt(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      httpClient.close();
    }
  }

  Future<Uint8List> _renderMarkerWithImage(
    ui.Image image, Color borderColor, bool showRadarRings,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _markerWidth, _markerHeight));

    _drawMarkerShape(canvas, borderColor, showRadarRings);
    _drawImageInCircle(canvas, image);
    _drawInnerBorder(canvas, borderColor);

    final picture = recorder.endRecording();
    final img = await picture.toImage(_markerWidth.toInt(), _markerHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderFallbackMarker(Color borderColor, bool showRadarRings) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _markerWidth, _markerHeight));

    _drawMarkerShape(canvas, borderColor, showRadarRings);

    final innerRadius = (_markerWidth / 2) - _borderWidth - 4;
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);

    // Camera icon placeholder
    final iconPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final iconSize = innerRadius * 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: iconSize * 1.4, height: iconSize),
        const Radius.circular(4),
      ),
      iconPaint,
    );
    canvas.drawCircle(center, iconSize * 0.3, iconPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(_markerWidth.toInt(), _markerHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  void _drawMarkerShape(Canvas canvas, Color borderColor, bool showRadarRings) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final radius = (_markerWidth / 2) - _shadowBlur;

    // Radar rings for urgent markers
    if (showRadarRings) {
      for (final (r, alpha, sw) in [
        (radius + 28, 0.08, 2.0),
        (radius + 18, 0.15, 2.0),
        (radius + 8, 0.25, 2.5),
      ]) {
        canvas.drawCircle(center, r,
            Paint()..color = borderColor.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = sw);
        canvas.drawCircle(center, r,
            Paint()..color = borderColor.withValues(alpha: alpha * 0.5));
      }
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowBlur);
    canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);
    final shadowTail = Path()
      ..moveTo(_markerWidth / 2 - 18, _markerWidth / 2 + radius * 0.6)
      ..lineTo(_markerWidth / 2, _markerHeight - _shadowBlur + 2)
      ..lineTo(_markerWidth / 2 + 18, _markerWidth / 2 + radius * 0.6)
      ..close();
    canvas.drawPath(shadowTail, shadowPaint);

    // Border fill
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, borderPaint);
    final tail = Path()
      ..moveTo(_markerWidth / 2 - 16, _markerWidth / 2 + radius * 0.6)
      ..lineTo(_markerWidth / 2, _markerHeight - _shadowBlur)
      ..lineTo(_markerWidth / 2 + 16, _markerWidth / 2 + radius * 0.6)
      ..close();
    canvas.drawPath(tail, borderPaint);
  }

  void _drawImageInCircle(Canvas canvas, ui.Image image) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final innerRadius = (_markerWidth / 2) - _shadowBlur - _borderWidth;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCircle(center: center, radius: innerRadius),
      Paint(),
    );
    canvas.restore();
  }

  void _drawInnerBorder(Canvas canvas, Color borderColor) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final innerRadius = (_markerWidth / 2) - _shadowBlur - _borderWidth;
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void clearCache() => _cache.clear();
}
