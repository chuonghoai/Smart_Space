import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:mobile_shared/util/media_metadata_sanitizer.dart';
import 'package:path_provider/path_provider.dart';

/// Đại diện cho một media item (hình ảnh hoặc video) có thể tải về.
class MediaGalleryItem {
  final String url;
  final bool isVideo;
  final String? fileName;
  final DateTime? createdAt;
  final String? messageId;

  const MediaGalleryItem({
    required this.url,
    required this.isVideo,
    this.fileName,
    this.createdAt,
    this.messageId,
  });
}

/// Dịch vụ tải ảnh / video về thiết bị chạy ngầm độc lập với UI.
/// - Lưu trực tiếp vào thư viện thiết bị (MediaStore / Photos) thông qua Gal để hiển thị ngay trong Gallery.
/// - Tự động bóc tách và xóa sạch toàn bộ metadata nhạy cảm (GPS, timestamps, camera model) nhưng bảo toàn orientation.
/// - Hiển thị SnackBar tiến trình tải duy trì liên tục cho đến khi hoàn thành,
///   cho phép người dùng tự do đóng full screen viewer hoặc chuyển màn hình khác mà không bị hủy.
class MediaDownloadService {
  static final MediaDownloadService _instance = MediaDownloadService._internal();

  factory MediaDownloadService() => _instance;

  MediaDownloadService._internal();

  /// Bắt đầu tải media chạy ngầm và thông báo trạng thái qua root [scaffoldMessengerKey].
  Future<void> downloadMedia(
    MediaGalleryItem item, {
    required String downloadingText,
    required String successText,
    required String failedText,
  }) async {
    // 1. Hiển thị SnackBar tiến trình (duy trì vô hạn cho đến khi tải xong)
    _showProgressSnackBar(downloadingText);

    // 2. Chạy tác vụ tải và lưu ngầm
    _executeDownload(
      item: item,
      successText: successText,
      failedText: failedText,
    );
  }

  void _showProgressSnackBar(String text) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1), // Duy trì cho đến khi bị ẩn/thay thế
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showResultSnackBar({
    required bool isSuccess,
    required String message,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _resolveExtension(MediaGalleryItem item) {
    if (item.isVideo) return 'mp4';
    if (item.fileName != null && item.fileName!.contains('.')) {
      final ext = item.fileName!.split('.').last.toLowerCase();
      if (ext.isNotEmpty) return ext;
    }
    final uriPath = Uri.tryParse(item.url)?.path.toLowerCase() ?? '';
    if (uriPath.endsWith('.png')) return 'png';
    if (uriPath.endsWith('.webp')) return 'webp';
    if (uriPath.endsWith('.gif')) return 'gif';
    return 'jpg';
  }

  Future<void> _executeDownload({
    required MediaGalleryItem item,
    required String successText,
    required String failedText,
  }) async {
    File? tempFile;
    try {
      final ext = _resolveExtension(item);
      final tempDir = await getTemporaryDirectory();
      tempFile = File(
        '${tempDir.path}/media_download_${DateTime.now().microsecondsSinceEpoch}.$ext',
      );

      // Tải về file tạm từ URL hoặc sao chép từ local file
      if (File(item.url).existsSync()) {
        await File(item.url).copy(tempFile.path);
      } else {
        final dio = Dio();
        await dio.download(item.url, tempFile.path);
      }

      // Xóa siêu dữ liệu nhạy cảm nhưng giữ lại orientation
      final cleanBytes = await MediaMetadataSanitizer.sanitizeFile(tempFile);
      await tempFile.writeAsBytes(cleanBytes, flush: true);

      // Lưu vào thư viện thiết bị
      if (Platform.isAndroid || Platform.isIOS) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            throw Exception('Permission to access gallery was denied');
          }
        }

        if (item.isVideo) {
          await Gal.putVideo(tempFile.path);
        } else {
          await Gal.putImage(tempFile.path);
        }
      } else {
        // Desktop / other platform fallback
        final baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final fileName = item.fileName ?? 'media_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final targetFile = File('${baseDir.path}/$fileName');
        await tempFile.copy(targetFile.path);
      }

      _showResultSnackBar(isSuccess: true, message: successText);
    } catch (e, stack) {
      debugPrint('[MediaDownloadService] Download failed: $e\n$stack');
      _showResultSnackBar(isSuccess: false, message: failedText);
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }
}

/// Global singleton tiện dụng để gọi ở bất kỳ đâu
final mediaDownloadService = MediaDownloadService();

