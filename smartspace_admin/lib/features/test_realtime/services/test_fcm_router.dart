import 'package:flutter/foundation.dart';

/// Một router đơn giản để test việc xử lý FCM Tap payload
class TestFcmRouter {
  /// Xử lý payload khi người dùng tap vào một notification (local hoặc từ OS tray)
  static void handleTap(Map<String, dynamic> payload) {
    debugPrint('[TestFcmRouter] Processing FCM Tap Payload: $payload');
    
    final type = payload['type'] as String?;
    
    if (type == 'TEST_NOTIFICATION') {
      debugPrint('[TestFcmRouter] Recognized TEST_NOTIFICATION. Action Data: ${payload['actionData']}');
      // Thử điều hướng hoặc xử lý logic
      // appRouter.push('/some-test-route');
    } else {
      debugPrint('[TestFcmRouter] Unhandled notification type: $type');
    }
  }
}
