import 'package:flutter/material.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_admin/features/notifications/models/notification_action.dart';

class NotificationRouter {
  static void handleAction(NotificationAction action) {
    final ctx = sharedNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('[NotificationRouter] Context is null or not mounted');
      return;
    }

    switch (action.type) {
      case 'REPORT_DETAIL':
        final reportId = action.payload['reportId'] as String?;
        debugPrint('[NotificationRouter] Action REPORT_DETAIL clicked for reportId: $reportId');
        // TODO: Chuyển hướng tới trang chi tiết phản ánh của Admin khi màn hình chi tiết được triển khai
        break;
      default:
        debugPrint('[NotificationRouter] Unhandled action type: ${action.type}');
    }
  }
}
