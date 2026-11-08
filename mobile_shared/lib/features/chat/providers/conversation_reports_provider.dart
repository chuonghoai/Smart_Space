import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/conversation_info_model.dart';
import 'package:mobile_shared/features/chat/models/linked_report_model.dart';
import 'package:mobile_shared/features/chat/services/chat_local_storage_service.dart';

class ConversationReportsState {
  final ConversationInfoModel? info;
  final List<LinkedReportModel> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  const ConversationReportsState({
    this.info,
    this.reports = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.page = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  ConversationReportsState copyWith({
    ConversationInfoModel? info,
    List<LinkedReportModel>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    int? page,
    bool? hasMore,
    String? errorMessage,
  }) {
    return ConversationReportsState(
      info: info ?? this.info,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class ConversationReportsNotifier
    extends StateNotifier<ConversationReportsState> {
  final String conversationId;
  final ChatRepository _repository;
  final ChatLocalStorageService _localStorageService;

  ConversationReportsNotifier({
    required this.conversationId,
    required ChatRepository repository,
    required ChatLocalStorageService localStorageService,
  })  : _repository = repository,
        _localStorageService = localStorageService,
        super(const ConversationReportsState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final infoRes = await _repository.getConversationInfo(conversationId);
      final reportsRes =
          await _repository.getConversationReports(conversationId, page: 1, size: 10);

      final info = infoRes.data;
      final reports = reportsRes.data ?? [];

      state = state.copyWith(
        info: info,
        reports: reports,
        isLoading: false,
        page: 1,
        hasMore: reports.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    try {
      final res = await _repository.getConversationReports(conversationId,
          page: nextPage, size: 10);
      final newItems = res.data ?? [];

      final existingIds = state.reports.map((e) => e.id).toSet();
      final filteredNew =
          newItems.where((e) => !existingIds.contains(e.id)).toList();

      state = state.copyWith(
        reports: [...state.reports, ...filteredNew],
        page: nextPage,
        hasMore: newItems.length >= 10,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> refreshAndSyncLocalMessages() async {
    state = state.copyWith(isRefreshing: true);
    try {
      // 1. Refresh Info & Reports Page 1
      final infoRes = await _repository.getConversationInfo(conversationId);
      final reportsRes =
          await _repository.getConversationReports(conversationId, page: 1, size: 10);

      // 2. Refresh Latest Messages and save to Local Storage
      final msgRes =
          await _repository.getMessages(conversationId, page: 1, size: 20);
      if (msgRes.success && msgRes.data != null && msgRes.data!.isNotEmpty) {
        await _localStorageService.saveMessages(conversationId, msgRes.data!);
      }

      final info = infoRes.data ?? state.info;
      final reports = reportsRes.data ?? [];

      state = state.copyWith(
        info: info,
        reports: reports,
        page: 1,
        hasMore: reports.length >= 10,
        isRefreshing: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
      return false;
    }
  }
}

final conversationReportsProvider = StateNotifierProvider.family<
    ConversationReportsNotifier, ConversationReportsState, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  final storage = ref.watch(chatLocalStorageServiceProvider);
  return ConversationReportsNotifier(
    conversationId: conversationId,
    repository: repo,
    localStorageService: storage,
  );
});
