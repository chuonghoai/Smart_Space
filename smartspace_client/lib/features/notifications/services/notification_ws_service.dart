import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/features/reports/providers/nearby_reports_alert_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/features/app_services/ws_services_registry.dart';

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
                // Update Unread Count qua Riverpod
                ProviderScope.containerOf(context)
                    .read(notificationProvider.notifier)
                    .onNotificationReceived();

                // Trigger nearby reports modal immediately if alert received
                if (action != null && action.type == 'NEARBY_REPORTS_ALERT') {
                  final lat = (action.payload['lat'] as num?)?.toDouble();
                  final lng = (action.payload['lng'] as num?)?.toDouble();
                  Position? pos;
                  if (lat != null && lng != null) {
                    pos = Position(
                      latitude: lat,
                      longitude: lng,
                      timestamp: DateTime.now(),
                      accuracy: 0.0,
                      altitude: 0.0,
                      altitudeAccuracy: 0.0,
                      heading: 0.0,
                      headingAccuracy: 0.0,
                      speed: 0.0,
                      speedAccuracy: 0.0,
                    );
                  }
                  ProviderScope.containerOf(context)
                      .read(nearbyReportsAlertProvider.notifier)
                      .checkNearbyReportsAlert(
                        customPosition: pos,
                        forceShow: false,
                        notify: false,
                      );
                }

                // Show toast
                final l10n = AppLocalizations.of(context);
                final actionLabel = l10n?.actionView;
                final finalAction = action;

                Toast.showTopNotification(
                  context: null,
                  title: title,
                  message: message,
                  actionLabel: finalAction != null && finalAction.type.isNotEmpty ? actionLabel : null,
                  onAction: finalAction != null && finalAction.type.isNotEmpty ? () => NotificationRouter.handleAction(finalAction) : null,
                );
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
