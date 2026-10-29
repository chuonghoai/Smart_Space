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
      case 'STAFF_WITHDRAWAL':
      case 'WITHDRAWAL':
        final withdrawalId = (action.payload['withdrawalId'] ?? action.payload['id']) as String?;
        if (withdrawalId != null && withdrawalId.isNotEmpty) {
          final path = RouterPath.staffWithdrawalDetailWithId(withdrawalId);
          debugPrint('[NotificationRouter] Navigating to detail: $path');
          GoRouter.of(ctx).push(path);
        } else {
          final status = (action.payload['status'] ?? '').toString().toUpperCase();
          final filter = status == 'APPROVED'
              ? 'approved'
              : (status == 'REJECTED' ? 'rejected' : 'all');
          final path = '${RouterPath.staffWithdrawalHistory}?filter=$filter';
          debugPrint('[NotificationRouter] Navigating to fallback history: $path');
          GoRouter.of(ctx).push(path);
        }
        break;
      case 'STAFF_WALLET':
      case 'WALLET':
        final path = RouterPath.staffWallet;
        debugPrint('[NotificationRouter] Navigating to $path');
        GoRouter.of(ctx).push(path);
        break;
      // Add other feature cases here, e.g. INVOICE_DETAIL, CHAT_MESSAGE
      default:
        debugPrint('[NotificationRouter] Unhandled action type: ${action.type}');
    }
  }
}

