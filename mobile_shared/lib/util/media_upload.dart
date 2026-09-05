import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/api/api_client.dart';

class MediaUploadUtil {
  static final MediaUploadUtil _instance = MediaUploadUtil._internal();

  factory MediaUploadUtil() {
    return _instance;
  }

  MediaUploadUtil._internal();

  Map<String, dynamic>? _cachedSignature;
  Future<Map<String, dynamic>>? _fetchSignatureFuture;

  Future<Map<String, dynamic>> _getSignature({bool forceRefresh = false}) {
    if (forceRefresh || _cachedSignature == null) {
      _fetchSignatureFuture ??= _fetchNewSignature().whenComplete(() {
        _fetchSignatureFuture = null;
      });
      return _fetchSignatureFuture!;
    }
    return Future.value(_cachedSignature!);
  }

  Future<Map<String, dynamic>> _fetchNewSignature() async {
    final sigResponse = await apiClient.get<Map<String, dynamic>>(
      '/media/signature',
      decoder: (json) => json as Map<String, dynamic>,
    );
    if (!sigResponse.success || sigResponse.data == null) {
      throw Exception('Không thể lấy signature: ${sigResponse.message}');
    }
    _cachedSignature = sigResponse.data!;
    return _cachedSignature!;
  }

  /// Upload file lên Cloudinary
  Future<String> uploadMedia(Uint8List bytes, String fileName) async {
    return _uploadMediaInternal(bytes, fileName, isRetry: false);
  }

  Future<String> _uploadMediaInternal(
    Uint8List bytes,
    String fileName, {
    required bool isRetry,
  }) async {
    final sigData = await _getSignature(forceRefresh: isRetry);
    final String cloudName = sigData['cloud_name'];
    final String apiKey = sigData['api_key'];
    final String signature = sigData['signature'];
    final int timestamp = sigData['timestamp'];
    final String folder = sigData['folder'];
    final String tags = sigData['tags'];

    // Upload trực tiếp lên Cloudinary
    final cloudinaryDio = Dio();
    final cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      'folder': folder,
      'tags': tags,
    });

    Map<String, dynamic> uploadData;
    try {
      final uploadResponse = await cloudinaryDio.post(
        cloudinaryUrl,
        data: formData,
      );
      if (uploadResponse.statusCode != 200) {
        throw Exception(
          'Upload Cloudinary thất bại: ${uploadResponse.statusCode}',
        );
      }
      uploadData = uploadResponse.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Check if the error is related to signature expiration/invalidity
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      String errorMessage = '';
      if (responseData is Map && responseData['error'] is Map) {
        errorMessage = responseData['error']['message']?.toString().toLowerCase() ?? '';
      }

      final isSignatureError = statusCode == 400 || statusCode == 401;
      final hasSignatureKeyword = errorMessage.contains('signature') || errorMessage.contains('expire');

      if (!isRetry && isSignatureError && hasSignatureKeyword) {
        debugPrint('▶ [MediaUpload] Signature lỗi/hết hạn. Retry fetch mới...');
        return _uploadMediaInternal(bytes, fileName, isRetry: true);
      }
      rethrow; // Throw for other errors (network, other cloudinary errors, etc.)
    }

    final String publicId = uploadData['public_id'];
    final String secureUrl = uploadData['secure_url'];
    debugPrint('▶ [MediaUpload] Cloudinary OK: publicId=$publicId');

    // Xác nhận với backend (xoá tag "tmp")
    await apiClient.post(
      '/media/confirm',
      data: {
        'publicId': publicId,
        'secureUrl': secureUrl,
        'resourceType': 'image',
      },
    );
    debugPrint('▶ [MediaUpload] Confirm OK: secureUrl=$secureUrl');
    return secureUrl;
  }
}

final mediaUploadUtil = MediaUploadUtil();
