import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef OnConversationUpdateCallback = void Function(ConversationModel conversation);
typedef OnTotalUnreadCallback = void Function(int totalUnread);

class ChatWsService implements WsFeatureService {
  StompUnsubscribe? _conversationsSub;
  final List<OnConversationUpdateCallback> _conversationListeners = [];
  final List<OnTotalUnreadCallback> _unreadListeners = [];

  void addConversationListener(OnConversationUpdateCallback listener) {
    if (!_conversationListeners.contains(listener)) {
      _conversationListeners.add(listener);
    }
  }

  void removeConversationListener(OnConversationUpdateCallback listener) {
    _conversationListeners.remove(listener);
  }

  void addUnreadListener(OnTotalUnreadCallback listener) {
    if (!_unreadListeners.contains(listener)) {
      _unreadListeners.add(listener);
    }
  }

  void removeUnreadListener(OnTotalUnreadCallback listener) {
    _unreadListeners.remove(listener);
  }

  @override
  void setup() {
    if (_conversationsSub != null) {
      debugPrint('[ChatWsService] Conversations listener already set up, skipping.');
      return;
    }

    debugPrint('[ChatWsService] Subscribing to /user/queue/conversations...');
    try {
      _conversationsSub = webSocketService.subscribe(
        destination: '/user/queue/conversations',
        callback: (frame) {
          debugPrint('[ChatWsService] Received conversation update frame: ${frame.body}');
          if (frame.body != null) {
            try {
              final data = dart_convert.jsonDecode(frame.body!) as Map<String, dynamic>;
              final model = ConversationModel.fromJson(data);
              for (final listener in List.of(_conversationListeners)) {
                listener(model);
              }
            } catch (e) {
              debugPrint('[ChatWsService] Parse error in conversation update: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('[ChatWsService] subscribe() threw: $e');
    }
  }

  StompUnsubscribe? subscribeToConversationTopic({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessage,
  }) {
    final destination = '/topic/conversation.$conversationId';
    debugPrint('[ChatWsService] Subscribing to $destination...');
    try {
      return webSocketService.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = dart_convert.jsonDecode(frame.body!) as Map<String, dynamic>;
              final model = ChatMessageModel.fromJson(data);
              onMessage(model);
            } catch (e) {
              debugPrint('[ChatWsService] Parse error in chat message frame: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('[ChatWsService] Error subscribing to conversation topic: $e');
      return null;
    }
  }

  bool get isConnected => webSocketService.isConnected;

  bool sendMessage({
    required String conversationId,
    required String content,
    required String tempId,
    String messageType = 'text',
  }) {
    if (!webSocketService.isConnected) {
      debugPrint('[ChatWsService] WebSocket is not connected, cannot send via WS');
      return false;
    }

    try {
      final payload = {
        'conversationId': conversationId,
        'content': content,
        'tempId': tempId,
        'messageType': messageType,
      };

      debugPrint('[ChatWsService] Sending message via WS to /smartspace/chat.send: $payload');
      webSocketService.send(
        destination: '/smartspace/chat.send',
        body: dart_convert.jsonEncode(payload),
      );
      return true;
    } catch (e) {
      debugPrint('[ChatWsService] Error sending message via WS: $e');
      return false;
    }
  }

  @override
  void reset() {
    _conversationsSub?.call();
    _conversationsSub = null;
  }

  @override
  void dispose() {
    _conversationsSub?.call();
    _conversationsSub = null;
    _conversationListeners.clear();
    _unreadListeners.clear();
  }
}

final chatWsService = ChatWsService();
