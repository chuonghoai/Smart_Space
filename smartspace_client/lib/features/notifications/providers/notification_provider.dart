import 'dart:async';
import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_client/features/notifications/services/notification_service.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class NotificationState {
  final NotificationCountModel? countModel;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;

  NotificationState({
    this.countModel,
    this.isLoading = false,
    this.error,
    this.lastFetched,
  });

  NotificationState copyWith({
    NotificationCountModel? countModel,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
  }) {
    return NotificationState(
      countModel: countModel ?? this.countModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState()) {
    fetchCount();
  }

  StompUnsubscribe? _wsSubscription;
  Timer? _fetchCountTimer;

  Future<void> fetchCount({bool forceRefresh = false}) async {
    // Check TTL
    if (!forceRefresh && state.lastFetched != null) {
      final diff = DateTime.now().difference(state.lastFetched!);
      if (diff.inMinutes < 10) {
        return; // Use cache
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getUnreadCount();
      if (response.success && response.data != null) {
        state = state.copyWith(
          countModel: response.data,
          isLoading: false,
          lastFetched: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setupWebSocketListener({
    required String actionLabel,
    required void Function(String) onAction,
  }) {
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
              final actionData = data['actionData'] != null ? dart_convert.jsonDecode(data['actionData']) : null;
              final reportId = actionData?['reportId'];

              debugPrint('[WS-Notif] Parsed — title=$title, reportId=$reportId');

              // Delay việc gọi API fetchCount 1.5 giây để đảm bảo backend đã commit
              // transaction vào database. Nếu có nhiều event liên tiếp, các timer cũ 
              // sẽ bị huỷ (debounce) để tránh spam API.
              _fetchCountTimer?.cancel();
              _fetchCountTimer = Timer(const Duration(milliseconds: 1000), () {
                fetchCount(forceRefresh: true);
              });

              // Show toast
              Toast.showTopNotification(
                context: null,
                title: title,
                message: message,
                actionLabel: reportId != null ? actionLabel : null,
                onAction: reportId != null ? () => onAction(reportId) : null,
              );
            } catch (e) {
              debugPrint('[WS-Notif] Parse error: $e');
            }
          }
        },
      );
      if (_wsSubscription != null) {
        debugPrint('[WS-Notif] ✅ Subscribed successfully!');
      } else {
        debugPrint('[WS-Notif] ⚠️ subscribe() returned null (WS not connected?)');
      }
    } catch (e) {
      debugPrint('[WS-Notif] ❌ subscribe() threw: $e');
    }
  }

  /// Call this when the connection drops so the subscription guard is cleared
  /// and the next call to setupWebSocketListener() will re-subscribe.
  void resetWebSocketSubscription() {
    if (_wsSubscription != null) {
      debugPrint('[WS-Notif] Connection dropped — clearing subscription for future re-subscribe.');
      _wsSubscription?.call(); // send UNSUBSCRIBE frame if still connected
      _wsSubscription = null;
    }
  }

  @override
  void dispose() {
    _fetchCountTimer?.cancel();
    _wsSubscription?.call();
    super.dispose();
  }
}

// keepAlive is true by default when not using autoDispose
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(notificationService);
    });
