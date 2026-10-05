import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Utility class để tạo hình ảnh marker tùy chỉnh cho Mapbox.
/// Marker có dạng hình giọt nước (pin-drop) với ảnh report bên trong.
class MarkerImageGenerator {
  /// Cache các marker đã render để tránh tải lại
  final Map<String, Uint8List> _cache = {};

  /// Kích thước mặc định của marker (pixel)
  static const double _markerWidth = 240;
  static const double _markerHeight = 300;
  static const double _borderWidth = 8;
  static const double _shadowBlur = 10;

  /// Tạo hình ảnh marker với ảnh report bên trong.
  ///
  /// [imageUrl] - URL ảnh của report
  /// [borderColor] - Màu viền marker (đỏ = nguy hiểm, teal = bình thường)
  /// [cacheKey] - Key dùng để cache, thường là report ID
  ///
  /// Trả về [Uint8List] PNG bytes, hoặc fallback marker nếu tải ảnh thất bại.
  Future<Uint8List> generateMarkerImage({
    required String imageUrl,
    required Color borderColor,
    required String cacheKey,
    bool isDangerous = false,
  }) async {
    // Kiểm tra cache
    final fullKey = '${cacheKey}_${borderColor.toARGB32()}_$isDangerous';
    if (_cache.containsKey(fullKey)) {
      return _cache[fullKey]!;
    }

    // Thử tải ảnh từ URL
    ui.Image? reportImage;
    if (imageUrl.isNotEmpty) {
      try {
        reportImage = await _loadImageFromUrl(imageUrl);
      } catch (e) {
        debugPrint('[MarkerGen] Failed to load image: $imageUrl — $e');
      }
    }

    // Render marker
    final Uint8List bytes;
    if (reportImage != null) {
      bytes = await _renderMarkerWithImage(
        reportImage,
        borderColor,
        isDangerous,
      );
      reportImage.dispose();
    } else {
      bytes = await _renderFallbackMarker(borderColor, isDangerous);
    }

    // Lưu cache
    _cache[fullKey] = bytes;
    return bytes;
  }

  /// Tải ảnh từ URL và decode thành [ui.Image]
  Future<ui.Image> _loadImageFromUrl(String url) async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
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

  /// Render marker hình giọt nước với ảnh report bên trong
  Future<Uint8List> _renderMarkerWithImage(
    ui.Image image,
    Color borderColor,
    bool isDangerous,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _markerWidth, _markerHeight),
    );

    _drawMarkerShape(canvas, borderColor, isDangerous);
    _drawImageInCircle(canvas, image);
    _drawInnerBorder(canvas, borderColor);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      _markerWidth.toInt(),
      _markerHeight.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Render marker fallback (không có ảnh, chỉ icon placeholder)
  Future<Uint8List> _renderFallbackMarker(
    Color borderColor,
    bool isDangerous,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _markerWidth, _markerHeight),
    );

    _drawMarkerShape(canvas, borderColor, isDangerous);

    // Vẽ hình tròn trắng bên trong
    final innerRadius = (_markerWidth / 2) - _borderWidth - 4;
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // Vẽ icon camera placeholder
    final iconPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final iconSize = innerRadius * 0.6;
    final iconCenter = center;

    // Vẽ hình chữ nhật (thân camera)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: iconCenter,
        width: iconSize * 1.4,
        height: iconSize,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, iconPaint);

    // Vẽ hình tròn (lens camera)
    canvas.drawCircle(iconCenter, iconSize * 0.3, iconPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      _markerWidth.toInt(),
      _markerHeight.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Vẽ hình dạng marker (giọt nước) với shadow
  void _drawMarkerShape(Canvas canvas, Color borderColor, bool isDangerous) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final radius = (_markerWidth / 2) - _shadowBlur;

    // RADAR RINGS (chỉ cho marker nguy hiểm)
    if (isDangerous) {
      // Vòng ngoài cùng — mờ nhất
      final ring3 = Paint()
        ..color = borderColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 28, ring3);

      // Fill nhẹ vòng ngoài
      final fill3 = Paint()
        ..color = borderColor.withValues(alpha: 0.04);
      canvas.drawCircle(center, radius + 28, fill3);

      // Vòng giữa
      final ring2 = Paint()
        ..color = borderColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 18, ring2);

      // Fill nhẹ vòng giữa
      final fill2 = Paint()
        ..color = borderColor.withValues(alpha: 0.06);
      canvas.drawCircle(center, radius + 18, fill2);

      // Vòng trong — đậm nhất
      final ring1 = Paint()
        ..color = borderColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius + 8, ring1);

      // Fill nhẹ vòng trong
      final fill1 = Paint()
        ..color = borderColor.withValues(alpha: 0.08);
      canvas.drawCircle(center, radius + 8, fill1);
    }

    // SHADOW
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowBlur);

    // Shadow cho phần tròn
    canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);

    // Shadow cho đuôi nhọn
    final shadowTailPath = Path()
      ..moveTo(_markerWidth / 2 - 18, _markerWidth / 2 + radius * 0.6)
      ..lineTo(_markerWidth / 2, _markerHeight - _shadowBlur + 2)
      ..lineTo(_markerWidth / 2 + 18, _markerWidth / 2 + radius * 0.6)
      ..close();
    canvas.drawPath(shadowTailPath, shadowPaint);

    // VIỀN MARKER (hình tròn + đuôi nhọn)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Vẽ hình tròn chính
    canvas.drawCircle(center, radius, borderPaint);

    // Vẽ đuôi nhọn (tam giác)
    final tailPath = Path()
      ..moveTo(_markerWidth / 2 - 16, _markerWidth / 2 + radius * 0.6)
      ..lineTo(_markerWidth / 2, _markerHeight - _shadowBlur)
      ..lineTo(_markerWidth / 2 + 16, _markerWidth / 2 + radius * 0.6)
      ..close();
    canvas.drawPath(tailPath, borderPaint);
  }

  /// Vẽ ảnh report bên trong hình tròn (clip tròn)
  void _drawImageInCircle(Canvas canvas, ui.Image image) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final innerRadius = (_markerWidth / 2) - _shadowBlur - _borderWidth;

    canvas.save();

    // Clip thành hình tròn
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.clipPath(clipPath);

    // Vẽ ảnh lấp đầy hình tròn (cover)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromCircle(center: center, radius: innerRadius);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    canvas.restore();
  }

  /// Vẽ viền tròn mỏng bên trong (aesthetic inner border)
  void _drawInnerBorder(Canvas canvas, Color borderColor) {
    final center = Offset(_markerWidth / 2, _markerWidth / 2);
    final innerRadius = (_markerWidth / 2) - _shadowBlur - _borderWidth;

    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, innerRadius, innerBorderPaint);
  }

  /// Xóa cache
  void clearCache() {
    _cache.clear();
  }
}
