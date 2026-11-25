import 'dart:async';
import 'dart:convert' as dart_convert;

import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class CallWsService implements WsFeatureService {
  StompUnsubscribe? _callSub;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isConnected => webSocketService.isConnected;
  bool get isSubscribed => _callSub != null;

  bool ensureSubscribed() {
    if (!webSocketService.isConnected) {
      return false;
    }
    if (_callSub == null) {
      setup();
    }
    return _callSub != null;
  }

  @override
  void setup() {
    if (!webSocketService.isConnected) {
      return;
    }
    if (_callSub == null) {
      try {
        _callSub = webSocketService.subscribe(
          destination: '/user/queue/call',
          callback: (frame) {
            if (frame.body == null || frame.body!.isEmpty) return;
            try {
              final map = dart_convert.jsonDecode(frame.body!) as Map<String, dynamic>;
              _eventController.add(map);
            } catch (e) {
              debugPrint('[CallWsService] Failed to parse call event: $e');
            }
          },
        );
        debugPrint('[CallWsService] Subscribed to /user/queue/call');
      } catch (e) {
        debugPrint('[CallWsService] Subscribe error: $e');
        _callSub = null;
      }
    }
  }

  bool sendRinging(String callId) => _send('/smartspace/call.ringing', {'callId': callId});

  bool sendConnected(String callId) => _send('/smartspace/call.connected', {'callId': callId});

  bool sendReject(String callId, {String? reason}) => _send('/smartspace/call.reject', {
        'callId': callId,
        if (reason != null) 'reason': reason,
      });

  bool sendCancel(String callId) => _send('/smartspace/call.cancel', {'callId': callId});

  bool sendEnd(String callId, {String? reason}) => _send('/smartspace/call.end', {
        'callId': callId,
        if (reason != null) 'reason': reason,
      });

  bool sendSignal({
    required String callId,
    required String signalType,
    String? sdp,
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) {
    return _send('/smartspace/call.signal', {
      'callId': callId,
      'signalType': signalType,
      if (sdp != null) 'sdp': sdp,
      if (candidate != null) 'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
    });
  }

  bool _send(String destination, Map<String, dynamic> body) {
    if (!webSocketService.isConnected) return false;
    try {
      webSocketService.send(
        destination: destination,
        body: dart_convert.jsonEncode(body),
      );
      return true;
    } catch (e) {
      debugPrint('[CallWsService] Send to $destination failed: $e');
      return false;
    }
  }

  @override
  void reset() {
    _callSub?.call();
    _callSub = null;
  }

  @override
  void dispose() {
    reset();
  }
}

final callWsService = CallWsService();
