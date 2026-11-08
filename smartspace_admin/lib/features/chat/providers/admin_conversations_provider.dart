import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';

class AdminConversationsState {
  final List<ConversationModel> conversations;
  final String activeFilter; // 'all', 'client', 'staff', 'admin'
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final int totalUnreadCount;
  final String? slidingInId;
  final String? pulseHighlightId;
  final String searchQuery;
  final List<PositionModel> availablePositions;
  final Set<String> selectedPositionIds;
  final bool isLoadingPositions;

  const AdminConversationsState({
    this.conversations = const [],
    this.activeFilter = 'all',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.totalUnreadCount = 0,
    this.slidingInId,
    this.pulseHighlightId,
    this.searchQuery = '',
    this.availablePositions = const [],
    this.selectedPositionIds = const {},
    this.isLoadingPositions = false,
  });

  AdminConversationsState copyWith({
    List<ConversationModel>? conversations,
    String? activeFilter,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
    int? totalUnreadCount,
    String? slidingInId,
    String? pulseHighlightId,
    String? searchQuery,
    List<PositionModel>? availablePositions,
    Set<String>? selectedPositionIds,
    bool? isLoadingPositions,
    bool clearSlidingIn = false,
    bool clearPulse = false,
  }) {
    return AdminConversationsState(
      conversations: conversations ?? this.conversations,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      slidingInId: clearSlidingIn ? null : (slidingInId ?? this.slidingInId),
      pulseHighlightId: clearPulse ? null : (pulseHighlightId ?? this.pulseHighlightId),
      searchQuery: searchQuery ?? this.searchQuery,
      availablePositions: availablePositions ?? this.availablePositions,
      selectedPositionIds: selectedPositionIds ?? this.selectedPositionIds,
      isLoadingPositions: isLoadingPositions ?? this.isLoadingPositions,
    );
  }
}

class AdminConversationsNotifier extends StateNotifier<AdminConversationsState> {
  final ChatRepository _repository;
  final ChatWsService _wsService;
  bool _isDisposed = false;
  Timer? _searchDebounce;

  AdminConversationsNotifier({
    ChatRepository? repository,
    ChatWsService? wsService,
  })  : _repository = repository ?? chatRepository,
        _wsService = wsService ?? chatWsService,
        super(const AdminConversationsState()) {
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

  Future<void> loadPositions() async {
    if (state.isLoadingPositions || state.availablePositions.isNotEmpty) return;
    state = state.copyWith(isLoadingPositions: true);
    try {
      final res = await _repository.getPositions();
      if (_isDisposed) return;
      if (res.success && res.data != null) {
        state = state.copyWith(
          availablePositions: res.data!,
          isLoadingPositions: false,
        );
      } else {
        state = state.copyWith(isLoadingPositions: false);
      }
    } catch (_) {
      if (!_isDisposed) {
        state = state.copyWith(isLoadingPositions: false);
      }
    }
  }

  Future<void> setFilter(String filter) async {
    if (state.activeFilter == filter) return;
    state = state.copyWith(activeFilter: filter);
    if (filter == 'staff' || filter == 'all') {
      loadPositions();
    }
    await loadInitial(filter);
  }

  void togglePosition(String positionId) {
    final next = Set<String>.from(state.selectedPositionIds);
    if (next.contains(positionId)) {
      next.remove(positionId);
    } else {
      next.add(positionId);
    }
    state = state.copyWith(selectedPositionIds: next);
    loadInitial(state.activeFilter);
  }

  void clearPositions() {
    if (state.selectedPositionIds.isEmpty) return;
    state = state.copyWith(selectedPositionIds: const {});
    loadInitial(state.activeFilter);
  }

  void onSearchQueryChanged(String query) {
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      loadInitial(state.activeFilter);
    });
  }

  void markAsReadLocally(String conversationId) {
    if (_isDisposed) return;
    final currentList = List<ConversationModel>.from(state.conversations);
    final index = currentList.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      final old = currentList[index];
      if (old.unreadCount > 0) {
        final decremented = old.unreadCount;
        currentList[index] = old.copyWith(unreadCount: 0);
        final newTotal = (state.totalUnreadCount - decremented).clamp(0, 999999);
        state = state.copyWith(
          conversations: currentList,
          totalUnreadCount: newTotal,
        );
      }
    }
  }

  Future<void> loadInitial(String filter) async {
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
        role: filter,
        positionIds: state.selectedPositionIds.isNotEmpty ? state.selectedPositionIds.toList() : null,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        state = state.copyWith(
          conversations: res.data!,
          isLoading: false,
          page: 1,
          hasMore: res.data!.length >= 15,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'Lỗi tải danh sách',
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      }
    }
  }

  Future<void> loadOlder() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final res = await _repository.getConversations(
        page: nextPage,
        size: 15,
        role: state.activeFilter,
        positionIds: state.selectedPositionIds.isNotEmpty ? state.selectedPositionIds.toList() : null,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      if (_isDisposed) return;

      if (res.success && res.data != null) {
        final incoming = res.data!;
        final existingIds = state.conversations.map((c) => c.id).toSet();
        final filtered = incoming.where((c) => !existingIds.contains(c.id)).toList();

        state = state.copyWith(
          conversations: [...state.conversations, ...filtered],
          isLoadingMore: false,
          page: nextPage,
          hasMore: incoming.length >= 15,
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

  Future<void> refresh() async {
    await loadInitial(state.activeFilter);
    await refreshUnreadCount();
  }

  void _handleWsConversationUpdate(ConversationModel updatedConv) {
    if (_isDisposed) return;

    // Filter check: If activeFilter is specific, check if it matches
    final partnerRole = updatedConv.partnerRole?.toLowerCase();
    if (state.activeFilter != 'all') {
      if (partnerRole != state.activeFilter) {
        // Remove from list if it no longer matches
        final remaining = state.conversations.where((c) => c.id != updatedConv.id).toList();
        state = state.copyWith(conversations: remaining);
        refreshUnreadCount();
        return;
      }
    }

    final existingIndex = state.conversations.indexWhere((c) => c.id == updatedConv.id);
    final list = List<ConversationModel>.from(state.conversations);

    if (existingIndex >= 0) {
      list.removeAt(existingIndex);
      list.insert(0, updatedConv);
      state = state.copyWith(
        conversations: list,
        pulseHighlightId: updatedConv.id,
      );
    } else {
      list.insert(0, updatedConv);
      state = state.copyWith(
        conversations: list,
        slidingInId: updatedConv.id,
        pulseHighlightId: updatedConv.id,
      );
    }

    refreshUnreadCount();

    // Clear animations after delay
    Timer(const Duration(milliseconds: 600), () {
      if (!_isDisposed) {
        state = state.copyWith(clearSlidingIn: true);
      }
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (!_isDisposed) {
        state = state.copyWith(clearPulse: true);
      }
    });
  }
}

final adminConversationsProvider =
    StateNotifierProvider<AdminConversationsNotifier, AdminConversationsState>((ref) {
  return AdminConversationsNotifier();
});

final adminChatTotalUnreadProvider = Provider<int>((ref) {
  return ref.watch(adminConversationsProvider.select((s) => s.totalUnreadCount));
});

