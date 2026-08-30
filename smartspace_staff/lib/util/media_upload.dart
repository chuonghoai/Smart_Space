import 'dart:io';

class MediaUploadUtil {
  static final MediaUploadUtil _instance = MediaUploadUtil._internal();

  factory MediaUploadUtil() {
    return _instance;
  }

  MediaUploadUtil._internal();

  Future<String> uploadMedia(File file) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'https://ui-avatars.com/api/?name=TH&format=png';
  }
}

final mediaUploadUtil = MediaUploadUtil();
