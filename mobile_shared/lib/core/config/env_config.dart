import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String? _lanIp;

  static Future<void> init() async {
    try {
      final String jsonString = await rootBundle.loadString('packages/mobile_shared/assets/local.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      final ip = jsonMap['lanIp'] as String?;
      if (ip == null || ip.isEmpty) {
        throw Exception("lanIp is empty or not found in local.json");
      }
      _lanIp = ip;
    } catch (e) {
      throw Exception("Failed to load local.json. Please run 'npm run client:dev' or 'update_ip.ps1' to generate it. Error: $e");
    }
  }

  static int get apiTimeout {
    final timeoutStr =
        dotenv.env['API_TIMEOUT'] ??
        const String.fromEnvironment('API_TIMEOUT', defaultValue: '10000');
    return int.tryParse(timeoutStr) ?? 10000;
  }

  static String get apiBaseUrl {
    // Production environment
    const String envApiUrl = String.fromEnvironment('API_URL');
    if (envApiUrl.isNotEmpty) {
      return envApiUrl;
    }

    // Development environment
    final String port = dotenv.env['PORT'] ?? '3000';
    final String lanIp = _lanIp ?? dotenv.env['LAN_IP'] ?? '10.0.2.2';

    // Web config
    if (kIsWeb) {
      return 'http://localhost:$port';
    }

    // Physical device config
    const bool isPhysical = bool.fromEnvironment(
      'IS_PHYSICAL',
      defaultValue: false,
    );
    if (isPhysical) {
      return 'http://$lanIp:$port';
    }

    // Mobile
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$lanIp:$port';
      case TargetPlatform.iOS:
        return 'http://localhost:$port';
      default:
        return 'http://localhost:$port';
    }
  }

  static String get googleClientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ?? const String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  }
}
