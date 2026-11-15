import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/models/linked_report_model.dart';
import 'package:mobile_shared/features/chat/services/chat_ws_service.dart';
import 'package:mobile_shared/util/media_upload.dart';
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
  final bool isPartnerTyping;
  final DateTime? partnerLastReadAt;

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
    this.isPartnerTyping = false,
    this.partnerLastReadAt,
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
    bool? isPartnerTyping,
    DateTime? partnerLastReadAt,
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
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      partnerLastReadAt: partnerLastReadAt ?? this.partnerLastReadAt,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  String conversationId;
  final ChatRepository _repository;
  final ChatWsService _wsService;
  Timer? _heartbeatTimer;
  Timer? _typingTimer;
  StompUnsubscribe? _topicSub;
  bool _isDisposed = false;
  bool _isActive = true;
  bool get isActive => _isActive;

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    if (_isActive) {
      _repository.enterPresence(conversationId);
      markAsRead();
    } else {
      _repository.leavePresence(conversationId);
    }
  }

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
    _typingTimer?.cancel();
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

    // Subscribe to STOMP topic for realtime messages, read receipts & typing
    _topicSub = _wsService.subscribeToConversationTopic(
      conversationId: conversationId,
      onMessage: _handleNewMessage,
      onReadReceipt: _handleReadReceipt,
      onTyping: _handleTyping,
    );

    // Enter presence in Redis and start 30s heartbeat if active
    if (_isActive) {
      _repository.enterPresence(conversationId);
      markAsRead();
    }

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isDisposed && _isActive) {
        _repository.heartbeatPresence(conversationId);
      }
    });
  }

  Future<void> markAsRead() async {
    if (state.isDraft) return;
    if (state.conversation != null) {
      final conv = state.conversation!;
      final isAnon = conv.isAnonymous;
      state = state.copyWith(
        conversation: conv.copyWith(
          unreadCount: 0,
          identifiedUnreadCount: isAnon ? conv.identifiedUnreadCount : 0,
          anonymousUnreadCount: isAnon ? 0 : conv.anonymousUnreadCount,
        ),
      );
    }
    try {
      _wsService.sendMarkAsRead(conversationId);
      await _repository.markAsRead(conversationId);
    } catch (_) {}
  }

  Future<void> onAppResumed() async {
    if (_isDisposed || state.isDraft) return;
    debugPrint('[ChatDetailNotifier] App resumed, syncing latest messages and presence for $conversationId');
    if (_isActive) {
      _repository.enterPresence(conversationId);
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_isDisposed && _isActive) {
          _repository.heartbeatPresence(conversationId);
        }
      });
      markAsRead();
    }
    await syncLatestMessages();
  }

  void onAppPaused() {
    if (_isDisposed || state.isDraft) return;
    debugPrint('[ChatDetailNotifier] App paused, leaving presence for $conversationId');
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _repository.leavePresence(conversationId);
  }

  Future<void> syncLatestMessages() async {
    if (_isDisposed || state.isDraft) return;
    try {
      final convRes = await _repository.getConversationDetail(conversationId);
      DateTime? partnerLastReadAt = state.partnerLastReadAt;
      if (convRes.success && convRes.data != null) {
        if (convRes.data!.partnerLastReadAt != null) {
          partnerLastReadAt = convRes.data!.partnerLastReadAt;
        }
      }

      final msgRes = await _repository.getMessages(conversationId, page: 1, size: 20);
      if (_isDisposed) return;

      if (msgRes.success && msgRes.data != null) {
        final incoming = msgRes.data!;
        final currentMessages = List<ChatMessageModel>.from(state.messages);

        for (final inc in incoming) {
          final idx = currentMessages.indexWhere(
            (m) => (inc.id != null && m.id == inc.id) || (inc.tempId != null && m.tempId == inc.tempId),
          );
          if (idx >= 0) {
            currentMessages[idx] = inc.copyWith(
              isSending: false,
              isFailed: false,
              isRead: inc.isRead ||
                  (partnerLastReadAt != null &&
                      inc.senderId == state.currentUserId &&
                      !inc.createdAt.isAfter(partnerLastReadAt)),
            );
          } else {
            currentMessages.insert(
              0,
              inc.copyWith(
                isRead: inc.isRead ||
                    (partnerLastReadAt != null &&
                        inc.senderId == state.currentUserId &&
                        !inc.createdAt.isAfter(partnerLastReadAt)),
              ),
            );
          }
        }

        currentMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        state = state.copyWith(
          conversation: convRes.data ?? state.conversation,
          partnerLastReadAt: partnerLastReadAt,
          messages: currentMessages,
        );

        if (_isActive) {
          markAsRead();
        }
      }
    } catch (e) {
      debugPrint('[ChatDetailNotifier] Error syncing latest messages: $e');
    }
  }

  void sendTyping(bool isTyping) {
    if (state.isDraft) return;
    _wsService.sendTyping(conversationId: conversationId, isTyping: isTyping);
  }

  void _handleReadReceipt(String readerId, DateTime readAt) {
    if (_isDisposed || readerId == state.currentUserId) return;
    final updated = state.messages.map((m) {
      if (m.senderId == state.currentUserId) {
        final isRead = m.isRead || !m.createdAt.isAfter(readAt);
        return m.copyWith(isRead: isRead);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated, partnerLastReadAt: readAt);
  }

  void _handleTyping(String userId, bool isTyping) {
    if (_isDisposed || userId == state.currentUserId) return;
    _typingTimer?.cancel();
    if (isTyping) {
      state = state.copyWith(isPartnerTyping: true);
      _typingTimer = Timer(const Duration(seconds: 4), () {
        if (!_isDisposed) {
          state = state.copyWith(isPartnerTyping: false);
        }
      });
    } else {
      state = state.copyWith(isPartnerTyping: false);
    }
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
      DateTime? partnerLastReadAt = state.partnerLastReadAt;
      if (convRes.success && convRes.data != null) {
        conversation = convRes.data!;
        if (conversation.partnerLastReadAt != null) {
          partnerLastReadAt = conversation.partnerLastReadAt;
        }
      }

      // 2. Fetch initial messages
      final msgRes = await _repository.getMessages(
        conversationId,
        page: 1,
        size: 20,
      );
      if (_isDisposed) return;

      if (msgRes.success && msgRes.data != null) {
        final rawMessages = msgRes.data!;
        final messages = rawMessages.map((m) {
          if (m.senderId == state.currentUserId && partnerLastReadAt != null) {
            final isRead = m.isRead || !m.createdAt.isAfter(partnerLastReadAt);
            return m.copyWith(isRead: isRead);
          }
          return m;
        }).toList();

        state = state.copyWith(
          conversation: conversation,
          partnerLastReadAt: partnerLastReadAt,
          messages: messages,
          isLoading: false,
          page: 1,
          hasMore: rawMessages.length >= 20,
        );
      } else {
        state = state.copyWith(
          conversation: conversation,
          partnerLastReadAt: partnerLastReadAt,
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
        final filteredOlder = older.where((m) => m.id == null || !existingIds.contains(m.id)).map((m) {
          if (m.senderId == state.currentUserId && state.partnerLastReadAt != null) {
            final isRead = m.isRead || !m.createdAt.isAfter(state.partnerLastReadAt!);
            return m.copyWith(isRead: isRead);
          }
          return m;
        }).toList();

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

  Future<String> _ensureConversationCreated() async {
    if (!state.isDraft || state.draftPartnerId == null) {
      return state.conversationId;
    }

    final convRes = await _repository.createOrGetConversation(
      participantIds: [state.draftPartnerId!],
    );
    if (convRes.success && convRes.data != null) {
      final realConv = convRes.data!;
      conversationId = realConv.id;
      state = state.copyWith(
        conversationId: realConv.id,
        conversation: realConv,
        isDraft: false,
      );

      _topicSub = _wsService.subscribeToConversationTopic(
        conversationId: realConv.id,
        onMessage: _handleNewMessage,
        onReadReceipt: _handleReadReceipt,
        onTyping: _handleTyping,
      );
      _repository.enterPresence(realConv.id);
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_isDisposed) {
          _repository.heartbeatPresence(realConv.id);
        }
      });
      return realConv.id;
    }
    throw Exception('Failed to create conversation');
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
      messageType: 'TEXT',
      createdAt: DateTime.now(),
      isSending: true,
    );

    state = state.copyWith(
      messages: [optimisticMsg, ...state.messages],
      isSending: true,
    );

    try {
      final targetConvId = await _ensureConversationCreated();

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
        await _sendViaRest(targetConvId, trimmed, tempId, messageType: 'text');
      } else {
        Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
          if (msgStillSending) {
            _sendViaRest(targetConvId, trimmed, tempId, messageType: 'text');
          }
        });
      }
    } catch (_) {
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> sendMediaMessage({
    required Uint8List bytes,
    required String fileName,
    required bool isVideo,
    String? localPath,
  }) async {
    if (!state.canSendMessage) return;

    final tempId = 'temp_media_${DateTime.now().microsecondsSinceEpoch}';
    final messageType = isVideo ? 'VIDEO' : 'IMAGE';
    final fallbackContent = isVideo ? '[Video]' : '[Hình ảnh]';

    final optimisticMsg = ChatMessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: state.currentUserId ?? '',
      content: fallbackContent,
      messageType: messageType,
      createdAt: DateTime.now(),
      isSending: true,
      localMediaPath: localPath,
    );

    state = state.copyWith(
      messages: [optimisticMsg, ...state.messages],
      isSending: true,
    );

    try {
      final targetConvId = await _ensureConversationCreated();

      // 1. Upload to Cloudinary
      final secureUrl = await mediaUploadUtil.uploadMedia(
        bytes,
        fileName,
        resourceType: isVideo ? 'video' : 'image',
      );

      final mediaModel = MessageMediaModel(
        fileName: fileName,
        fileType: isVideo ? 'video/mp4' : 'image/jpeg',
        thumbnailUrl: secureUrl,
      );
      final mediaDto = [mediaModel.toJson()];

      // Cập nhật optimisticMsg trong state với media vừa upload
      final updatedList = state.messages.map((m) {
        if (m.tempId == tempId) {
          return m.copyWith(messageMedia: [mediaModel]);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedList);

      // 2. Send via WS / REST
      bool sentViaWs = false;
      if (_repository.isWsConnected) {
        sentViaWs = _repository.sendMessageWs(
          conversationId: targetConvId,
          content: fallbackContent,
          tempId: tempId,
          messageType: isVideo ? 'video' : 'image',
          messageMedia: mediaDto,
        );
      }

      if (!sentViaWs) {
        await _sendViaRest(
          targetConvId,
          fallbackContent,
          tempId,
          messageType: isVideo ? 'video' : 'image',
          messageMedia: mediaDto,
        );
      } else {
        Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
          if (msgStillSending) {
            _sendViaRest(
              targetConvId,
              fallbackContent,
              tempId,
              messageType: isVideo ? 'video' : 'image',
              messageMedia: mediaDto,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[ChatDetailProvider] sendMediaMessage error: $e');
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> sendAudioMessage({
    required Uint8List bytes,
    required String fileName,
    required int durationSeconds,
    String? localPath,
  }) async {
    if (!state.canSendMessage) return;

    final tempId = 'temp_audio_${DateTime.now().microsecondsSinceEpoch}';
    final content = '$durationSeconds';

    final optimisticMsg = ChatMessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: state.currentUserId ?? '',
      content: content,
      messageType: 'AUDIO',
      createdAt: DateTime.now(),
      isSending: true,
      localMediaPath: localPath,
    );

    state = state.copyWith(
      messages: [optimisticMsg, ...state.messages],
      isSending: true,
    );

    try {
      final targetConvId = await _ensureConversationCreated();

      // Upload audio to Cloudinary
      final secureUrl = await mediaUploadUtil.uploadMedia(
        bytes,
        fileName,
        resourceType: 'video',
      );

      final audioModel = MessageMediaModel(
        fileName: fileName,
        fileType: 'audio/m4a',
        thumbnailUrl: secureUrl,
      );
      final mediaDto = [audioModel.toJson()];

      // Cập nhật optimisticMsg trong state với audio vừa upload
      final updatedList = state.messages.map((m) {
        if (m.tempId == tempId) {
          return m.copyWith(messageMedia: [audioModel]);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedList);

      bool sentViaWs = false;
      if (_repository.isWsConnected) {
        sentViaWs = _repository.sendMessageWs(
          conversationId: targetConvId,
          content: content,
          tempId: tempId,
          messageType: 'audio',
          messageMedia: mediaDto,
        );
      }

      if (!sentViaWs) {
        await _sendViaRest(
          targetConvId,
          content,
          tempId,
          messageType: 'audio',
          messageMedia: mediaDto,
        );
      } else {
        Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
          if (msgStillSending) {
            _sendViaRest(
              targetConvId,
              content,
              tempId,
              messageType: 'audio',
              messageMedia: mediaDto,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[ChatDetailProvider] sendAudioMessage error: $e');
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> sendReportMessage(LinkedReportModel report) async {
    if (!state.canSendMessage) return;

    final tempId = 'temp_report_${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMsg = ChatMessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: state.currentUserId ?? '',
      content: report.title,
      messageType: 'REPORT',
      createdAt: DateTime.now(),
      isSending: true,
      report: report,
    );

    state = state.copyWith(
      messages: [optimisticMsg, ...state.messages],
      isSending: true,
    );

    try {
      final targetConvId = await _ensureConversationCreated();

      bool sentViaWs = false;
      if (_repository.isWsConnected) {
        sentViaWs = _repository.sendMessageWs(
          conversationId: targetConvId,
          content: report.title,
          tempId: tempId,
          messageType: 'report',
          reportId: report.id,
        );
      }

      if (!sentViaWs) {
        await _sendViaRest(
          targetConvId,
          report.title,
          tempId,
          messageType: 'report',
          reportId: report.id,
        );
      } else {
        Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
          if (msgStillSending) {
            _sendViaRest(
              targetConvId,
              report.title,
              tempId,
              messageType: 'report',
              reportId: report.id,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[ChatDetailProvider] sendReportMessage error: $e');
      if (!_isDisposed) {
        _markMessageFailed(tempId);
      }
    }
  }

  Future<void> _sendViaRest(
    String targetConvId,
    String content,
    String tempId, {
    String messageType = 'text',
    List<Map<String, dynamic>>? messageMedia,
    String? reportId,
  }) async {
    try {
      final res = await _repository.sendMessage(
        conversationId: targetConvId,
        content: content,
        tempId: tempId,
        messageType: messageType,
        messageMedia: messageMedia,
        reportId: reportId,
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

    final list = state.messages.map((m) {
      if (m.tempId == tempId || m.id == tempId) {
        return m.copyWith(isSending: true, isFailed: false);
      }
      return m;
    }).toList();

    state = state.copyWith(messages: list);

    List<Map<String, dynamic>> mediaDto = failedMsg.messageMedia.map((m) => m.toJson()).toList();

    // Nếu messageMedia đang rỗng nhưng có file cục bộ (upload Cloudinary lần đầu thất bại):
    if (mediaDto.isEmpty && failedMsg.localMediaPath != null && File(failedMsg.localMediaPath!).existsSync()) {
      try {
        final file = File(failedMsg.localMediaPath!);
        final bytes = await file.readAsBytes();
        final fileName = file.uri.pathSegments.last;
        final isVideo = failedMsg.isVideo;
        final isAudio = failedMsg.isAudio;
        final resourceType = isVideo ? 'video' : (isAudio ? 'video' : 'image');
        final secureUrl = await mediaUploadUtil.uploadMedia(
          bytes,
          fileName,
          resourceType: resourceType,
        );
        final fileType = isAudio
            ? 'audio/m4a'
            : (isVideo ? 'video/mp4' : 'image/jpeg');
        final model = MessageMediaModel(
          fileName: fileName,
          fileType: fileType,
          thumbnailUrl: secureUrl,
        );
        mediaDto = [model.toJson()];
        final updatedList = state.messages.map((m) {
          if (m.tempId == tempId || m.id == tempId) {
            return m.copyWith(messageMedia: [model]);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedList);
      } catch (e) {
        debugPrint('[ChatDetailProvider] retry upload failed: $e');
        _markMessageFailed(tempId);
        return;
      }
    }

    bool sentViaWs = false;
    if (_repository.isWsConnected) {
      sentViaWs = _repository.sendMessageWs(
        conversationId: conversationId,
        content: failedMsg.content,
        tempId: tempId,
        messageType: failedMsg.messageType.toLowerCase(),
        messageMedia: mediaDto,
        reportId: failedMsg.report?.id,
      );
    }

    if (!sentViaWs) {
      await _sendViaRest(
        conversationId,
        failedMsg.content,
        tempId,
        messageType: failedMsg.messageType.toLowerCase(),
        messageMedia: mediaDto,
        reportId: failedMsg.report?.id,
      );
    } else {
      Timer(const Duration(seconds: 10), () {
        if (_isDisposed) return;
        final msgStillSending = state.messages.any((m) => m.tempId == tempId && m.isSending);
        if (msgStillSending) {
          _sendViaRest(
            conversationId,
            failedMsg.content,
            tempId,
            messageType: failedMsg.messageType.toLowerCase(),
            messageMedia: mediaDto,
            reportId: failedMsg.report?.id,
          );
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

    final existingIdx = state.messages.indexWhere((m) {
      if (message.id != null && m.id == message.id) return true;
      if (message.tempId != null && m.tempId == message.tempId) return true;
      return false;
    });

    if (existingIdx >= 0) {
      final list = List<ChatMessageModel>.from(state.messages);
      list[existingIdx] = message.copyWith(isSending: false, isFailed: false);
      state = state.copyWith(messages: list);
    } else {
      state = state.copyWith(messages: [message, ...state.messages]);
    }

    if (_isActive) {
      _repository.markAsRead(conversationId);
    }
  }
}

final chatDetailProvider =
    StateNotifierProvider.family.autoDispose<ChatDetailNotifier, ChatDetailState, String>(
  (ref, conversationId) {
    return ChatDetailNotifier(conversationId: conversationId);
  },
);
