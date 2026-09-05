import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smartspace_client/core/api/api_client.dart';

class MediaUploadUtil {
  static final MediaUploadUtil _instance = MediaUploadUtil._internal();

  factory MediaUploadUtil() {
    return _instance;
  }

  MediaUploadUtil._internal();

  /// Upload file lên Cloudinary
  Future<String> uploadMedia(Uint8List bytes, String fileName) async {
    final sigResponse = await apiClient.get<Map<String, dynamic>>(
      '/media/signature',
      decoder: (json) => json as Map<String, dynamic>,
    );
    if (!sigResponse.success || sigResponse.data == null) {
      throw Exception('Không thể lấy signature: ${sigResponse.message}');
    }

    final sigData = sigResponse.data!;
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
    final uploadResponse = await cloudinaryDio.post(
      cloudinaryUrl,
      data: formData,
    );
    if (uploadResponse.statusCode != 200) {
      throw Exception(
        'Upload Cloudinary thất bại: ${uploadResponse.statusCode}',
      );
    }
    final uploadData = uploadResponse.data as Map<String, dynamic>;
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
