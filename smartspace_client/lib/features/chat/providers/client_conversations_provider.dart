import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/services/chat_ws_service.dart';

class ClientConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final int totalUnreadCount;
  final String searchQuery;

  const ClientConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.totalUnreadCount = 0,
    this.searchQuery = '',
  });

  ClientConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
    int? totalUnreadCount,
    String? searchQuery,
  }) {
    return ClientConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ClientConversationsNotifier extends StateNotifier<ClientConversationsState> {
  final ChatRepository _repository;
  final ChatWsService _wsService;
  bool _isDisposed = false;
  Timer? _searchDebounce;

  ClientConversationsNotifier({
    ChatRepository? repository,
    ChatWsService? wsService,
  })  : _repository = repository ?? chatRepository,
        _wsService = wsService ?? chatWsService,
        super(const ClientConversationsState()) {
    _wsService.addConversationListener(_onConversationWsUpdate);
    _wsService.addUnreadListener(_onTotalUnreadWsUpdate);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounce?.cancel();
    _wsService.removeConversationListener(_onConversationWsUpdate);
    _wsService.removeUnreadListener(_onTotalUnreadWsUpdate);
    super.dispose();
  }

  void _onTotalUnreadWsUpdate(int totalUnread) {
    if (_isDisposed) return;
    state = state.copyWith(totalUnreadCount: totalUnread);
  }

  void _onConversationWsUpdate(ConversationModel updatedConv) {
    if (_isDisposed) return;

    final currentList = List<ConversationModel>.from(state.conversations);
    // Match by ID or partnerId or context IDs to merge identified & anonymous contexts
    final index = currentList.indexWhere((c) =>
        c.id == updatedConv.id ||
        (c.partnerId != null && c.partnerId == updatedConv.partnerId) ||
        (c.identifiedConversationId != null &&
            (c.identifiedConversationId == updatedConv.identifiedConversationId ||
             c.identifiedConversationId == updatedConv.id)) ||
        (c.anonymousConversationId != null &&
            (c.anonymousConversationId == updatedConv.anonymousConversationId ||
             c.anonymousConversationId == updatedConv.id)));

    if (index >= 0) {
      final existing = currentList[index];
      // Check if this update actually contains a new message
      final hasNewMessage = updatedConv.lastMessageId != null &&
          (existing.lastMessageId == null ||
           updatedConv.lastMessageId != existing.lastMessageId ||
           (updatedConv.lastMessageTime != null &&
            existing.lastMessageTime != null &&
            updatedConv.lastMessageTime!.isAfter(existing.lastMessageTime!)));

      if (hasNewMessage) {
        currentList.removeAt(index);
        currentList.insert(0, updatedConv);
      } else {
        // Read receipt / unread count update: update in-place without moving to top
        currentList[index] = updatedConv;
      }
    } else {
      currentList.insert(0, updatedConv);
    }

    if (updatedConv.totalUnreadCount != null) {
      state = state.copyWith(
        conversations: currentList,
        totalUnreadCount: updatedConv.totalUnreadCount!,
      );
    } else {
      state = state.copyWith(conversations: currentList);
      _fetchUnreadCount();
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await _repository.getUnreadCount();
      if (!_isDisposed && res.success && res.data != null) {
        state = state.copyWith(totalUnreadCount: res.data!);
      }
    } catch (_) {}
  }

  void markAsReadLocally(String conversationId) {
    if (_isDisposed) return;
    int unreadToSubtract = 0;
    final updatedList = state.conversations.map((c) {
      final matches = c.id == conversationId ||
          (c.identifiedConversationId != null && c.identifiedConversationId == conversationId) ||
          (c.anonymousConversationId != null && c.anonymousConversationId == conversationId);
      if (matches && c.unreadCount > 0) {
        unreadToSubtract = c.unreadCount;
        return c.copyWith(
          unreadCount: 0,
          identifiedUnreadCount: 0,
          anonymousUnreadCount: 0,
        );
      }
      return c;
    }).toList();

    if (unreadToSubtract > 0) {
      final newTotal = (state.totalUnreadCount - unreadToSubtract).clamp(0, 9999);
      state = state.copyWith(
        conversations: updatedList,
        totalUnreadCount: newTotal,
      );
    }
  }

  void markContextAsReadLocally(String conversationId, {required bool isAnonymous}) {
    if (_isDisposed) return;
    int unreadToSubtract = 0;
    final updatedList = state.conversations.map((c) {
      final matches = c.id == conversationId ||
          (c.identifiedConversationId != null && c.identifiedConversationId == conversationId) ||
          (c.anonymousConversationId != null && c.anonymousConversationId == conversationId);
      if (!matches) return c;

      if (isAnonymous) {
        unreadToSubtract = c.anonymousUnreadCount;
        final newUnread = (c.unreadCount - unreadToSubtract).clamp(0, 9999);
        return c.copyWith(
          anonymousUnreadCount: 0,
          unreadCount: newUnread,
        );
      } else {
        unreadToSubtract = c.identifiedUnreadCount;
        final newUnread = (c.unreadCount - unreadToSubtract).clamp(0, 9999);
        return c.copyWith(
          identifiedUnreadCount: 0,
          unreadCount: newUnread,
        );
      }
    }).toList();

    if (unreadToSubtract > 0) {
      final newTotal = (state.totalUnreadCount - unreadToSubtract).clamp(0, 9999);
      state = state.copyWith(
        conversations: updatedList,
        totalUnreadCount: newTotal,
      );
    } else {
      state = state.copyWith(conversations: updatedList);
    }
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null, page: 1, hasMore: true);

    try {
      final queryParam = state.searchQuery.trim().isNotEmpty ? state.searchQuery.trim() : null;
      final results = await Future.wait([
        _repository.getConversations(
          page: 1,
          size: 15,
          role: 'all',
          query: queryParam,
        ),
        _repository.getUnreadCount(),
      ]);

      if (_isDisposed) return;

      final convRes = results[0] as dynamic;
      final unreadRes = results[1] as dynamic;

      if (convRes.success && convRes.data != null) {
        final List<ConversationModel> items = convRes.data!;
        final unread = (unreadRes.success && unreadRes.data != null) ? unreadRes.data! as int : 0;

        state = state.copyWith(
          conversations: items,
          isLoading: false,
          page: 1,
          hasMore: items.length >= 15,
          totalUnreadCount: unread,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: convRes.message ?? 'errorLoadMessages',
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

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final queryParam = state.searchQuery.trim().isNotEmpty ? state.searchQuery.trim() : null;
      final res = await _repository.getConversations(
        page: nextPage,
        size: 15,
        role: 'all',
        query: queryParam,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final List<ConversationModel> items = res.data!;
        state = state.copyWith(
          conversations: [...state.conversations, ...items],
          isLoadingMore: false,
          page: nextPage,
          hasMore: items.length >= 15,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      loadInitial();
    });
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final clientConversationsProvider =
    StateNotifierProvider<ClientConversationsNotifier, ClientConversationsState>((ref) {
  final notifier = ClientConversationsNotifier();
  notifier.loadInitial();
  return notifier;
});

final clientChatTotalUnreadProvider = Provider<int>((ref) {
  return ref.watch(clientConversationsProvider.select((s) => s.totalUnreadCount));
});

