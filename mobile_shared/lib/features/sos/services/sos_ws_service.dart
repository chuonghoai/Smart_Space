import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Nghe /user/queue/sos và phát lại thành stream cho các provider SOS (client và admin).
class SosWsService implements WsFeatureService {
  final _events = StreamController<SosRealtimeEvent>.broadcast();
  StompUnsubscribe? _subscription;

  Stream<SosRealtimeEvent> get events => _events.stream;

  @override
  void setup() {
    if (_subscription != null) return;
    _subscription = webSocketService.subscribe(
      destination: '/user/queue/sos',
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final event = SosRealtimeEvent.fromJson(jsonDecode(body) as Map<String, dynamic>);
          if (event.sos.id.isNotEmpty) _events.add(event);
        } catch (e) {
          debugPrint('[WS-SOS] Parse error: $e');
        }
      },
    );
  }

  @override
  void reset() {
    _subscription?.call();
    _subscription = null;
  }

  @override
  void dispose() {
    reset();
  }
}

final sosWsService = SosWsService();
