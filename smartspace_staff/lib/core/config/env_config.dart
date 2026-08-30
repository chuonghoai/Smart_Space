import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
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
    final String lanIp = dotenv.env['LAN_IP'] ?? '10.0.2.2';

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
}
