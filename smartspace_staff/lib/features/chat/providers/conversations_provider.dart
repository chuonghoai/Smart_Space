import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/chat/data/chat_repository.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/services/chat_ws_service.dart';

class ConversationsState {
  final List<ConversationModel> conversations;
  final String activeFilter; // 'all', 'client', 'staff', 'admin'
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final int totalUnreadCount;
  final String? slidingOutId;
  final String? slidingInId;
  final String? pulseHighlightId;
  final String searchQuery;
  final List<ParticipantModel> searchedUsers;
  final bool isSearchingUsers;

  const ConversationsState({
    this.conversations = const [],
    this.activeFilter = 'all',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.totalUnreadCount = 0,
    this.slidingOutId,
    this.slidingInId,
    this.pulseHighlightId,
    this.searchQuery = '',
    this.searchedUsers = const [],
    this.isSearchingUsers = false,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    String? activeFilter,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
    int? totalUnreadCount,
    String? slidingOutId,
    String? slidingInId,
    String? pulseHighlightId,
    String? searchQuery,
    List<ParticipantModel>? searchedUsers,
    bool? isSearchingUsers,
    bool clearSlidingOut = false,
    bool clearSlidingIn = false,
    bool clearPulse = false,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      slidingOutId: clearSlidingOut ? null : (slidingOutId ?? this.slidingOutId),
      slidingInId: clearSlidingIn ? null : (slidingInId ?? this.slidingInId),
      pulseHighlightId: clearPulse ? null : (pulseHighlightId ?? this.pulseHighlightId),
      searchQuery: searchQuery ?? this.searchQuery,
      searchedUsers: searchedUsers ?? this.searchedUsers,
      isSearchingUsers: isSearchingUsers ?? this.isSearchingUsers,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ChatRepository _repository;
  final ChatWsService _wsService;
  bool _isDisposed = false;
  Timer? _searchDebounce;

  ConversationsNotifier({
    ChatRepository? repository,
    ChatWsService? wsService,
  })  : _repository = repository ?? chatRepository,
        _wsService = wsService ?? chatWsService,
        super(const ConversationsState()) {
    _wsService.addConversationListener(_handleWsConversationUpdate);
    loadInitial('all');
    refreshUnreadCount();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounce?.cancel();
    _wsService.removeConversationListener(_handleWsConversationUpdate);
    super.dispose();
  }

  Future<void> refreshUnreadCount() async {
    try {
      final res = await _repository.getUnreadCount();
      if (!_isDisposed && res.success && res.data != null) {
        state = state.copyWith(totalUnreadCount: res.data!);
      }
    } catch (_) {}
  }

  Future<void> setFilter(String filter) async {
    if (state.activeFilter == filter) return;
    state = state.copyWith(activeFilter: filter, searchedUsers: []);
    await loadInitial(filter, query: state.searchQuery);
    if (state.searchQuery.trim().isNotEmpty && filter != 'client') {
      _fetchOtherUsers(filter, state.searchQuery);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_isDisposed) return;
      loadInitial(state.activeFilter, query: query);
      if (query.trim().isNotEmpty && state.activeFilter != 'client') {
        _fetchOtherUsers(state.activeFilter, query);
      } else {
        state = state.copyWith(searchedUsers: [], isSearchingUsers: false);
      }
    });
  }

  Future<void> _fetchOtherUsers(String role, String query) async {
    state = state.copyWith(isSearchingUsers: true);
    try {
      final res = await _repository.searchUsers(role: role, query: query);
      if (_isDisposed) return;
      if (res.success && res.data != null) {
        // Exclude users who already appear in existing conversations
        final existingPartnerIds = state.conversations
            .map((c) => c.partnerId)
            .whereType<String>()
            .toSet();
        final filteredUsers = res.data!
            .where((u) => !existingPartnerIds.contains(u.userId))
            .toList();
        state = state.copyWith(searchedUsers: filteredUsers, isSearchingUsers: false);
      } else {
        state = state.copyWith(searchedUsers: [], isSearchingUsers: false);
      }
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(searchedUsers: [], isSearchingUsers: false);
      }
    }
  }

  Future<void> loadInitial(String role, {String? query}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      page: 1,
      hasMore: true,
    );

    try {
      final res = await _repository.getConversations(
        page: 1,
        size: 15,
        role: role,
        query: query,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final list = res.data!;
        state = state.copyWith(
          conversations: list,
          isLoading: false,
          page: 1,
          hasMore: list.length >= 15,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'errorLoadConversations',
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
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final res = await _repository.getConversations(
        page: nextPage,
        size: 15,
        role: state.activeFilter,
        query: state.searchQuery,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final newItems = res.data!;
        final existingIds = state.conversations.map((e) => e.id).toSet();
        final filteredNew = newItems.where((e) => !existingIds.contains(e.id)).toList();

        state = state.copyWith(
          conversations: [...state.conversations, ...filteredNew],
          isLoadingMore: false,
          page: nextPage,
          hasMore: newItems.length >= 15,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  Future<void> refresh() async {
    await loadInitial(state.activeFilter, query: state.searchQuery);
    if (state.searchQuery.trim().isNotEmpty && state.activeFilter != 'client') {
      _fetchOtherUsers(state.activeFilter, state.searchQuery);
    }
    await refreshUnreadCount();
  }

  void markConversationRead(String conversationId) {
    final list = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    state = state.copyWith(conversations: list);
    _repository.markAsRead(conversationId);
    refreshUnreadCount();
  }

  void _handleWsConversationUpdate(ConversationModel updated) async {
    if (_isDisposed) return;

    // Check filter match
    if (state.activeFilter == 'client' && !updated.isClient) return;
    if (state.activeFilter == 'staff' && !updated.isStaff) return;
    if (state.activeFilter == 'admin' && !updated.isAdmin) return;

    final existingIndex = state.conversations.indexWhere((c) => c.id == updated.id);

    if (existingIndex == 0) {
      final list = List<ConversationModel>.from(state.conversations);
      list[0] = updated;
      state = state.copyWith(conversations: list);
      refreshUnreadCount();
      return;
    }

    if (existingIndex > 0) {
      final movingItem = state.conversations[existingIndex];

      // Phase 1: Slide out to the left
      state = state.copyWith(slidingOutId: movingItem.id);
      await Future.delayed(const Duration(milliseconds: 250));
      if (_isDisposed) return;

      // Phase 2: Move to index 0, slide in from the left
      final list = List<ConversationModel>.from(state.conversations);
      list.removeAt(existingIndex);
      list.insert(0, updated);

      state = state.copyWith(
        conversations: list,
        clearSlidingOut: true,
        slidingInId: updated.id,
        pulseHighlightId: updated.id,
      );

      // Phase 3: Settle animation
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isDisposed) return;
      state = state.copyWith(clearSlidingIn: true);

      // Clear pulse after 2 seconds
      await Future.delayed(const Duration(milliseconds: 1700));
      if (_isDisposed) return;
      state = state.copyWith(clearPulse: true);

      refreshUnreadCount();
      return;
    }

    // New conversation not yet in list -> insert at 0
    final list = List<ConversationModel>.from(state.conversations);
    list.insert(0, updated);
    state = state.copyWith(
      conversations: list,
      slidingInId: updated.id,
      pulseHighlightId: updated.id,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;
    state = state.copyWith(clearSlidingIn: true);

    await Future.delayed(const Duration(milliseconds: 1700));
    if (_isDisposed) return;
    state = state.copyWith(clearPulse: true);

    refreshUnreadCount();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier();
});
