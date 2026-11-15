import 'dart:convert' as dart_convert;
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef OnConversationUpdateCallback = void Function(ConversationModel conversation);
typedef OnTotalUnreadCallback = void Function(int totalUnread);

class _TopicSubscriptionEntry {
  final String conversationId;
  final void Function(ChatMessageModel message) onMessage;
  final void Function(String readerId, DateTime readAt)? onReadReceipt;
  final void Function(String userId, bool isTyping)? onTyping;
  StompUnsubscribe? stompUnsubscribe;

  _TopicSubscriptionEntry({
    required this.conversationId,
    required this.onMessage,
    this.onReadReceipt,
    this.onTyping,
  });
}

class ChatWsService implements WsFeatureService {
  StompUnsubscribe? _conversationsSub;
  StompUnsubscribe? _unreadSub;
  final List<OnConversationUpdateCallback> _conversationListeners = [];
  final List<OnTotalUnreadCallback> _unreadListeners = [];
  final Map<String, _TopicSubscriptionEntry> _topicSubscriptions = {};

  void addConversationListener(OnConversationUpdateCallback listener) {
    if (!_conversationListeners.contains(listener)) {
      _conversationListeners.add(listener);
    }
    if ((_conversationsSub == null || _unreadSub == null) && webSocketService.isConnected) {
      setup();
    }
  }

  void removeConversationListener(OnConversationUpdateCallback listener) {
    _conversationListeners.remove(listener);
  }

  void addUnreadListener(OnTotalUnreadCallback listener) {
    if (!_unreadListeners.contains(listener)) {
      _unreadListeners.add(listener);
    }
    if ((_conversationsSub == null || _unreadSub == null) && webSocketService.isConnected) {
      setup();
    }
  }

  void removeUnreadListener(OnTotalUnreadCallback listener) {
    _unreadListeners.remove(listener);
  }

  @override
  void setup() {
    if (!webSocketService.isConnected) {
      debugPrint('[ChatWsService] WebSocket not connected yet, skipping setup until connected.');
      return;
    }

    if (_conversationsSub == null) {
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
                if (model.totalUnreadCount != null) {
                  for (final unreadListener in List.of(_unreadListeners)) {
                    unreadListener(model.totalUnreadCount!);
                  }
                }
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

    if (_unreadSub == null) {
      debugPrint('[ChatWsService] Subscribing to /user/queue/chat.unread...');
      try {
        _unreadSub = webSocketService.subscribe(
          destination: '/user/queue/chat.unread',
          callback: (frame) {
            debugPrint('[ChatWsService] Received chat.unread frame: ${frame.body}');
            if (frame.body != null) {
              try {
                final data = dart_convert.jsonDecode(frame.body!) as Map<String, dynamic>;
                final count = (data['totalUnreadCount'] as num?)?.toInt() ?? 0;
                for (final listener in List.of(_unreadListeners)) {
                  listener(count);
                }
              } catch (e) {
                debugPrint('[ChatWsService] Parse error in chat.unread: $e');
              }
            }
          },
        );
      } catch (e) {
        debugPrint('[ChatWsService] subscribe(chat.unread) threw: $e');
      }
    }

    // Automatically re-subscribe all active conversation topics on reconnect
    for (final entry in _topicSubscriptions.values) {
      _subscribeTopicInternal(entry);
    }
  }

  void _subscribeTopicInternal(_TopicSubscriptionEntry entry) {
    if (!webSocketService.isConnected) return;
    final destination = '/topic/conversation.${entry.conversationId}';
    debugPrint('[ChatWsService] Subscribing/Re-subscribing to $destination...');
    try {
      entry.stompUnsubscribe?.call();
      entry.stompUnsubscribe = webSocketService.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = dart_convert.jsonDecode(frame.body!) as Map<String, dynamic>;
              final type = data['type']?.toString();
              if (type == 'READ_RECEIPT') {
                final readerId = data['readerId']?.toString() ?? '';
                final readAt = DateTime.tryParse(data['readAt']?.toString() ?? '') ?? DateTime.now();
                entry.onReadReceipt?.call(readerId, readAt);
              } else if (type == 'TYPING') {
                final userId = data['userId']?.toString() ?? '';
                final isTyping = data['isTyping'] as bool? ?? false;
                entry.onTyping?.call(userId, isTyping);
              } else {
                final model = ChatMessageModel.fromJson(data);
                entry.onMessage(model);
              }
            } catch (e) {
              debugPrint('[ChatWsService] Parse error in chat message frame: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('[ChatWsService] Error subscribing to conversation topic: $e');
      entry.stompUnsubscribe = null;
    }
  }

  StompUnsubscribe? subscribeToConversationTopic({
    required String conversationId,
    required void Function(ChatMessageModel message) onMessage,
    void Function(String readerId, DateTime readAt)? onReadReceipt,
    void Function(String userId, bool isTyping)? onTyping,
  }) {
    // Unsubscribe existing if present
    _topicSubscriptions[conversationId]?.stompUnsubscribe?.call();

    final entry = _TopicSubscriptionEntry(
      conversationId: conversationId,
      onMessage: onMessage,
      onReadReceipt: onReadReceipt,
      onTyping: onTyping,
    );
    _topicSubscriptions[conversationId] = entry;

    if (webSocketService.isConnected) {
      _subscribeTopicInternal(entry);
    }

    return ({Map<String, String>? unsubscribeHeaders}) {
      entry.stompUnsubscribe?.call(unsubscribeHeaders: unsubscribeHeaders);
      entry.stompUnsubscribe = null;
      if (_topicSubscriptions[conversationId] == entry) {
        _topicSubscriptions.remove(conversationId);
      }
    };
  }

  bool get isConnected => webSocketService.isConnected;

  bool sendMessage({
    required String conversationId,
    required String content,
    required String tempId,
    String messageType = 'text',
    List<Map<String, dynamic>>? messageMedia,
    String? reportId,
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
        if (messageMedia != null && messageMedia.isNotEmpty) 'messageMedia': messageMedia,
        if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
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

  bool sendMarkAsRead(String conversationId) {
    if (!webSocketService.isConnected) {
      return false;
    }
    try {
      webSocketService.send(
        destination: '/smartspace/chat.read',
        body: dart_convert.jsonEncode({'conversationId': conversationId}),
      );
      return true;
    } catch (e) {
      debugPrint('[ChatWsService] Error sending mark as read via WS: $e');
      return false;
    }
  }

  bool sendTyping({required String conversationId, required bool isTyping}) {
    if (!webSocketService.isConnected) {
      return false;
    }
    try {
      webSocketService.send(
        destination: '/smartspace/chat.typing',
        body: dart_convert.jsonEncode({
          'conversationId': conversationId,
          'isTyping': isTyping,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('[ChatWsService] Error sending typing via WS: $e');
      return false;
    }
  }

  @override
  void reset() {
    _conversationsSub?.call();
    _conversationsSub = null;
    _unreadSub?.call();
    _unreadSub = null;
    for (final entry in _topicSubscriptions.values) {
      entry.stompUnsubscribe?.call();
      entry.stompUnsubscribe = null;
    }
  }

  @override
  void dispose() {
    _conversationsSub?.call();
    _conversationsSub = null;
    _unreadSub?.call();
    _unreadSub = null;
    for (final entry in _topicSubscriptions.values) {
      entry.stompUnsubscribe?.call();
      entry.stompUnsubscribe = null;
    }
    _topicSubscriptions.clear();
    _conversationListeners.clear();
    _unreadListeners.clear();
  }
}

final chatWsService = ChatWsService();

