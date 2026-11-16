import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/features/notifications/models/notification_action.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';

class NotificationRouter {
  static void handleAction(NotificationAction action) {
    final ctx = sharedNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('[NotificationRouter] Context is null, cannot navigate');
      return;
    }

    switch (action.type) {
      case 'REPORT':
      case 'REPORT_DETAIL':
        final reportId = (action.payload['reportId'] ?? action.payload['id']) as String?;
        if (reportId != null && reportId.isNotEmpty) {
          final path = RouterPath.reportDetail.replaceAll(':id', reportId);
          debugPrint('[NotificationRouter] Navigating to $path');
          GoRouter.of(ctx).push(path);
        } else {
          debugPrint('[NotificationRouter] Missing reportId in payload');
        }
        break;
      case 'NEWS':
      case 'NEWS_DETAIL':
        final newsId = (action.payload['newsId'] ?? action.payload['id']) as String?;
        if (newsId != null && newsId.isNotEmpty) {
          final path = RouterPath.newsDetailWithId(newsId);
          debugPrint('[NotificationRouter] Navigating to $path');
          GoRouter.of(ctx).push(path);
        } else {
          debugPrint('[NotificationRouter] Missing newsId in payload');
        }
        break;
      case 'STAFF_DELEGATION':
        // Chi tiết report có banner nhờ làm giùm kèm thao tác (nhận / từ chối / huỷ)
        final delegationReportId = action.payload['reportId'] as String?;
        final delegationPath = delegationReportId != null && delegationReportId.isNotEmpty
            ? RouterPath.reportDetail.replaceAll(':id', delegationReportId)
            : RouterPath.delegations;
        debugPrint('[NotificationRouter] Navigating to $delegationPath');
        GoRouter.of(ctx).push(delegationPath);
        break;
      case 'CHAT':
      case 'CHAT_DETAIL':
        final conversationId = (action.payload['conversationId'] ?? action.payload['id']) as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          final path = RouterPath.chatDetailWithId(conversationId);
          debugPrint('[NotificationRouter] Navigating to chat detail: $path');
          GoRouter.of(ctx).push(path);
        } else {
          final path = RouterPath.conversations;
          debugPrint('[NotificationRouter] Navigating to conversations list: $path');
          GoRouter.of(ctx).push(path);
        }
        break;
      // Add other feature cases here, e.g. INVOICE_DETAIL, CHAT_MESSAGE
      default:
        debugPrint('[NotificationRouter] Unhandled action type: ${action.type}');
    }
  }
}

