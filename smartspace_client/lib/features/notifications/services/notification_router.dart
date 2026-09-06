import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';

class NotificationRouter {
  static void handleAction(NotificationAction action) {
    final ctx = sharedNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('[NotificationRouter] Context is null, cannot navigate');
      return;
    }

    switch (action.type) {
      case 'REPORT_DETAIL':
        final reportId = action.payload['reportId'] as String?;
        if (reportId != null && reportId.isNotEmpty) {
          final path = RouterPath.reportDetail.replaceAll(':id', reportId);
          debugPrint('[NotificationRouter] Navigating to $path');
          GoRouter.of(ctx).push(path);
        } else {
          debugPrint('[NotificationRouter] Missing reportId in payload');
        }
        break;
      // Add other feature cases here, e.g. INVOICE_DETAIL, CHAT_MESSAGE
      default:
        debugPrint('[NotificationRouter] Unhandled action type: ${action.type}');
    }
  }
}
