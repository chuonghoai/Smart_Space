import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:smartspace_admin/features/app_services/ws_services_registry.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_action.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/features/notifications/services/notification_router.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class NotificationWsService implements WsFeatureService {
  StompUnsubscribe? _wsSubscription;

  @override
  void setup() {
    if (_wsSubscription != null) {
      debugPrint('[WS-Notif] Listener already set up, skipping.');
      return;
    }

    debugPrint('[WS-Notif] Attempting to subscribe to /user/queue/notifications...');
    try {
      _wsSubscription = webSocketService.subscribe(
        destination: '/user/queue/notifications',
        callback: (frame) {
          debugPrint('[WS-Notif] Received frame: ${frame.body}');
          if (frame.body != null) {
            try {
              final data = dart_convert.jsonDecode(frame.body!);
              final title = data['title'] ?? '';
              final message = data['message'] ?? '';
              
              NotificationAction? action;
              if (data['actionData'] != null) {
                final actionDataMap = dart_convert.jsonDecode(data['actionData']);
                action = NotificationAction.fromJson(actionDataMap);
              }

              // Lấy context từ global navigator key
              final context = sharedNavigatorKey.currentContext;
              if (context != null) {
                final container = ProviderScope.containerOf(context);

                // 1. Update unread notification count
                container
                    .read(notificationProvider.notifier)
                    .onNotificationReceived();

                // 2. Realtime update danh sách Pending / All reports và Overview nếu có report mới
                if (action != null && action.type == 'REPORT_DETAIL') {
                  final payload = action.payload;
                  final reportId = payload['reportId'] as String?;
                  if (reportId != null && reportId.isNotEmpty) {
                    final reportModel = RecentReportModel(
                      id: reportId,
                      title: payload['title'] as String? ?? message,
                      status: payload['status'] as String? ?? 'pending',
                      severity: payload['severity'] as String? ?? 'low',
                      createdAt: payload['createdAt'] as String? ?? DateTime.now().toIso8601String(),
                      imageUrl: payload['imageUrl'] as String?,
                    );

                    container.read(recentReportProvider('pending').notifier).prependReport(reportModel);
                    container.read(recentReportProvider('all').notifier).prependReport(reportModel);
                    container.read(adminOverviewProvider.notifier).incrementIssueCount();
                    container.read(recentActivityProvider.notifier).refresh();
                  }
                }

                // 3. Hiển thị Toast nổi
                final l10n = AppLocalizations.of(context);
                final actionLabel = l10n?.actionView;
                final finalAction = action;

                Toast.showTopNotification(
                  context: context,
                  title: title.isNotEmpty ? title : (l10n?.newReportToastTitle ?? 'Có phản ánh mới'),
                  message: message,
                  actionLabel: finalAction != null && finalAction.type.isNotEmpty ? actionLabel : null,
                  onAction: finalAction != null && finalAction.type.isNotEmpty 
                      ? () => NotificationRouter.handleAction(finalAction) 
                      : null,
                );
              } else {
                debugPrint('[WS-Notif] WARNING: sharedNavigatorKey.currentContext is null!');
              }
            } catch (e) {
              debugPrint('[WS-Notif] Parse error: $e');
            }
          }
        },
      );
      if (_wsSubscription != null) {
        debugPrint('[WS-Notif] Subscribed successfully!');
      } else {
        debugPrint('[WS-Notif] subscribe() returned null (WS not connected?)');
      }
    } catch (e) {
      debugPrint('[WS-Notif] subscribe() threw: $e');
    }
  }

  @override
  void reset() {
    if (_wsSubscription != null) {
      debugPrint('[WS-Notif] Connection dropped clearing subscription for future re-subscribe.');
      _wsSubscription?.call();
      _wsSubscription = null;
    }
  }

  @override
  void dispose() {
    _wsSubscription?.call();
    _wsSubscription = null;
  }
}
