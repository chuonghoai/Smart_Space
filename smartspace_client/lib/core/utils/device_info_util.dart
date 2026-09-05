import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:smartspace_client/core/storage/shared_preferences.dart';

class DeviceInfoUtil {
  static const _deviceIdKey = 'device_id';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Lấy hoặc tạo mới deviceId
  static Future<String> getDeviceId() async {
    String? storedId = await sharedPreferencesService.get<String>(_deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) return storedId;

    final newId = const Uuid().v4();
    await sharedPreferencesService.set(_deviceIdKey, newId);
    return newId;
  }

  /// Tên thiết bị (ví dụ: "Samsung Galaxy S24", "Chrome on Windows")
  static Future<String> getDeviceName() async {
    try {
      if (kIsWeb) return 'Web Browser';
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  /// Platform: "android", "ios", "web"
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
