import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:smartspace_admin/features/app_services/ws_services_registry.dart';

/// Một service đơn giản dùng để test hạ tầng WebSocket.
class TestWsService implements WsFeatureService {
  StompUnsubscribe? _wsSubscription;

  @override
  void setup() {
    if (_wsSubscription != null) {
      debugPrint('[TestWsService] Listener already set up, skipping.');
      return;
    }

    debugPrint('[TestWsService] Attempting to subscribe to /user/queue/test_event...');
    try {
      _wsSubscription = webSocketService.subscribe(
        destination: '/user/queue/test_event',
        callback: (frame) {
          debugPrint('[TestWsService] Received frame: ${frame.body}');
          if (frame.body != null) {
            try {
              final data = dart_convert.jsonDecode(frame.body!);
              debugPrint('[TestWsService] Parsed Test Event Data: $data');
              
              // Đây là nơi sẽ dispatch event tới state manager (ví dụ Riverpod)
              // hoặc hiển thị Toast notification
            } catch (e) {
              debugPrint('[TestWsService] Parse error: $e');
            }
          }
        },
      );
      if (_wsSubscription != null) {
        debugPrint('[TestWsService] Subscribed successfully!');
      } else {
        debugPrint('[TestWsService] subscribe() returned null (WS not connected?)');
      }
    } catch (e) {
      debugPrint('[TestWsService] subscribe() threw: $e');
    }
  }

  @override
  void reset() {
    if (_wsSubscription != null) {
      debugPrint('[TestWsService] Connection dropped, clearing subscription for future re-subscribe.');
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
