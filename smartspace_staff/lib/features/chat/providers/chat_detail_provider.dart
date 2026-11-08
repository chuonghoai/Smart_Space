import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_staff/features/chat/data/chat_repository.dart';
import 'package:smartspace_staff/features/chat/models/chat_message_model.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/services/chat_ws_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatDetailState {
  final String conversationId;
  final ConversationModel? conversation;
  final List<ChatMessageModel> messages; // Index 0 is newest (for reverse: true)
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final String? currentUserId;
  final bool isDraft;
  final String? draftPartnerId;

  const ChatDetailState({
    required this.conversationId,
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.currentUserId,
    this.isDraft = false,
    this.draftPartnerId,
  });

  bool get canSendMessage => conversation?.canSendMessage ?? true;

  ChatDetailState copyWith({
    String? conversationId,
    ConversationModel? conversation,
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    String? errorMessage,
    int? page,
    bool? hasMore,
    String? currentUserId,
    bool? isDraft,
    String? draftPartnerId,
  }) {
    return ChatDetailState(
      conversationId: conversationId ?? this.conversationId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      currentUserId: currentUserId ?? this.currentUserId,
      isDraft: isDraft ?? this.isDraft,
      draftPartnerId: draftPartnerId ?? this.draftPartnerId,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  String conversationId;
  final ChatRepository _repository;
  final ChatWsService _wsService;
  Timer? _heartbeatTimer;
  StompUnsubscribe? _topicSub;
  bool _isDisposed = false;

  ChatDetailNotifier({
    required this.conversationId,
    ChatRepository? repository,
    ChatWsService? wsService,
  })  : _repository = repository ?? chatRepository,
        _wsService = wsService ?? chatWsService,
        super(ChatDetailState(
          conversationId: conversationId,
          isDraft: conversationId.startsWith('new_'),
          draftPartnerId: conversationId.startsWith('new_') ? conversationId.substring(4) : null,
        )) {
    if (!state.isDraft) {
      _init();
    } else {
      _initDraft();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _topicSub?.call();
    if (!conversationId.startsWith('new_')) {
      _repository.leavePresence(conversationId);
    }
    super.dispose();
  }

  Future<void> _initDraft() async {
    final user = await userStorageService.getUser();
    if (!_isDisposed) {
      state = state.copyWith(
        currentUserId: user?.id,
        isLoading: false,
        messages: [],
      );
    }
  }

  Future<void> _init() async {
    final user = await userStorageService.getUser();
    if (!_isDisposed) {
      state = state.copyWith(currentUserId: user?.id);
    }

    await loadInitial();

    // Subscribe to STOMP topic for realtime messages in this conversation
    _topicSub = _wsService.subscribeToConversationTopic(
      conversationId: conversationId,
      onMessage: _handleNewMessage,
    );

    // Enter presence in Redis and start 30s heartbeat
    _repository.enterPresence(conversationId);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isDisposed) {
        _repository.heartbeatPresence(conversationId);
      }
    });

    // Mark as read
    _repository.markAsRead(conversationId);
  }

  Future<void> loadInitial() async {
    if (state.isDraft) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      page: 1,
      hasMore: true,
    );

    try {
      // 1. Fetch conversation details (canSendMessage, partner info)
      final convRes = await _repository.getConversationDetail(conversationId);
      if (_isDisposed) return;

      ConversationModel? conversation;
      if (convRes.success && convRes.data != null) {
        conversation = convRes.data!;
      }

      // 2. Fetch initial messages
      final msgRes = await _repository.getMessages(
        conversationId,
        page: 1,
        size: 20,
      );
      if (_isDisposed) return;

      if (msgRes.success && msgRes.data != null) {
        state = state.copyWith(
          conversation: conversation,
          messages: msgRes.data!,
          isLoading: false,
          page: 1,
          hasMore: msgRes.data!.length >= 20,
        );
      } else {
        state = state.copyWith(
          conversation: conversation,
          isLoading: false,
          errorMessage: msgRes.message.isNotEmpty ? msgRes.message : 'errorLoadMessages',
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> loadOlder() async {
    if (state.isDraft || state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final res = await _repository.getMessages(
        conversationId,
        page: nextPage,
        size: 20,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final older = res.data!;
        final existingIds = state.messages.map((m) => m.id).whereType<String>().toSet();
        final filteredOlder = older.where((m) => m.id == null || !existingIds.contains(m.id)).toList();

        state = state.copyWith(
          messages: [...state.messages, ...filteredOlder],
          isLoadingMore: false,
          page: nextPage,
          hasMore: older.length >= 20,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || !state.canSendMessage) return;

    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMsg = ChatMessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: state.currentUserId ?? '',
      content: trimmed,
      createdAt: DateTime.now(),
      isSending: true,
    );

    // Prepend optimistic message to messages
    state = state.copyWith(
      messages: [optimisticMsg, ...state.messages],
      isSending: true,
    );

    try {
      String targetConvId = state.conversationId;

      // Lazy creation: if in draft mode, create conversation in DB on first message
      if (state.isDraft && state.draftPartnerId != null) {
        final convRes = await _repository.createOrGetConversation(
          participantIds: [state.draftPartnerId!],
        );
        if (_isDisposed) return;
        if (convRes.success && convRes.data != null) {
          final realConv = convRes.data!;
          targetConvId = realConv.id;
          conversationId = realConv.id;
          state = state.copyWith(
            conversationId: realConv.id,
            conversation: realConv,
            isDraft: false,
          );

          // Subscribe to STOMP and enter presence
          _topicSub = _wsService.subscribeToConversationTopic(
            conversationId: realConv.id,
            onMessage: _handleNewMessage,
          );
          _repository.enterPresence(realConv.id);
          _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
            if (!_isDisposed) {
              _repository.heartbeatPresence(realConv.id);
            }
          });
        } else {
          _markMessageFailed(tempId);
          return;
        }
      }

      // Modern chat architecture: Try sending via WebSocket first, fallback to REST API
      bool sentViaWs = false;
      if (_repository.isWsConnected) {
        sentViaWs = _repository.sendMessageWs(
          conversationId: targetConvId,
          content: trimmed,
          tempId: tempId,
          messageType: 'text',
        );
      }

      if (!sentViaWs) {
        // WebSocket not connected or send failed -> Fallback to REST API immediately
        await _sendViaRest(targetConvId, trimmed, tempId);
      } else {
        // Sent via WS -> Start a 5-second confirmation timer
        Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
          if (msgStillSending) {
            _sendViaRest(targetConvId, trimmed, tempId);
          }
        });
      }
    } catch (_) {
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> _sendViaRest(String targetConvId, String content, String tempId) async {
    try {
      final res = await _repository.sendMessage(
        conversationId: targetConvId,
        content: content,
        tempId: tempId,
        messageType: 'text',
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final serverMsg = res.data!;
        final list = state.messages.map((m) {
          if (m.tempId == tempId) {
            return serverMsg.copyWith(tempId: tempId, isSending: false, isFailed: false);
          }
          return m;
        }).toList();

        state = state.copyWith(messages: list, isSending: false);
      } else {
        _markMessageFailed(tempId);
      }
    } catch (_) {
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> retryMessage(ChatMessageModel failedMsg) async {
    final tempId = failedMsg.tempId ?? failedMsg.id ?? '';
    if (tempId.isEmpty) return;

    // Reset failed to sending
    final list = state.messages.map((m) {
      if (m.tempId == tempId || m.id == tempId) {
        return m.copyWith(isSending: true, isFailed: false);
      }
      return m;
    }).toList();

    state = state.copyWith(messages: list);

    // Try WS first, fallback to REST
    bool sentViaWs = false;
    if (_repository.isWsConnected) {
      sentViaWs = _repository.sendMessageWs(
        conversationId: conversationId,
        content: failedMsg.content,
        tempId: tempId,
        messageType: 'text',
      );
    }

    if (!sentViaWs) {
      await _sendViaRest(conversationId, failedMsg.content, tempId);
    } else {
      Timer(const Duration(seconds: 5), () {
        if (_isDisposed) return;
        final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
        if (msgStillSending) {
          _sendViaRest(conversationId, failedMsg.content, tempId);
        }
      });
    }
  }

  void _markMessageFailed(String tempId) {
    final list = state.messages.map((m) {
      if (m.tempId == tempId) {
        return m.copyWith(isSending: false, isFailed: true);
      }
      return m;
    }).toList();

    state = state.copyWith(messages: list, isSending: false);
  }

  void _handleNewMessage(ChatMessageModel message) {
    if (_isDisposed) return;

    // Check if message is already in list (e.g. from optimistic send)
    final existingIdx = state.messages.indexWhere((m) {
      if (message.id != null && m.id == message.id) return true;
      if (message.tempId != null && m.tempId == message.tempId) return true;
      return false;
    });

    if (existingIdx >= 0) {
      // Replace with confirmed server message
      final list = List<ChatMessageModel>.from(state.messages);
      list[existingIdx] = message.copyWith(isSending: false, isFailed: false);
      state = state.copyWith(messages: list);
    } else {
      // Prepend to newest
      state = state.copyWith(messages: [message, ...state.messages]);
    }

    // Mark as read since user is actively in this conversation
    _repository.markAsRead(conversationId);
  }
}

final chatDetailProvider =
    StateNotifierProvider.family.autoDispose<ChatDetailNotifier, ChatDetailState, String>(
  (ref, conversationId) {
    return ChatDetailNotifier(conversationId: conversationId);
  },
);
