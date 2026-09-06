import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';

class NotificationWsService {
  StompUnsubscribe? _wsSubscription;
  final VoidCallback onNotificationReceived;
  final String actionLabel;

  NotificationWsService({
    required this.onNotificationReceived,
    required this.actionLabel,
  });

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

              // Notify UnreadCount Provider
              onNotificationReceived();

              final finalAction = action;

              // Show toast
              Toast.showTopNotification(
                context: null,
                title: title,
                message: message,
                actionLabel: finalAction != null && finalAction.type.isNotEmpty ? actionLabel : null,
                onAction: finalAction != null && finalAction.type.isNotEmpty ? () => NotificationRouter.handleAction(finalAction) : null,
              );
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

  void reset() {
    if (_wsSubscription != null) {
      debugPrint('[WS-Notif] Connection dropped clearing subscription for future re-subscribe.');
      _wsSubscription?.call();
      _wsSubscription = null;
    }
  }

  void dispose() {
    _wsSubscription?.call();
    _wsSubscription = null;
  }
}
