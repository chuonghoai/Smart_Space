import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      case 'REPORT_CREATED':
        final reportId = action.payload['reportId']?.toString();
        debugPrint('[NotificationRouter] Action ${action.type} clicked for reportId: $reportId');
        if (reportId != null && reportId.isNotEmpty) {
          ctx.push('/reports/$reportId');
        }
        break;
      default:
        debugPrint('[NotificationRouter] Unhandled action type: ${action.type}');
    }
  }
}
