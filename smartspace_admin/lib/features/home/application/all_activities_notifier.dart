import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../models/recent_activity_model.dart';

class AllActivitiesState {
  final List<RecentActivityModel> items;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String roleFilter; // 'all', 'admin', 'staff'
  final String topicFilter; // 'all', 'news', 'report_create', 'report_assign', 'report_process'

  const AllActivitiesState({
    this.items = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.roleFilter = 'all',
    this.topicFilter = 'all',
  });

  bool get hasMore => currentPage < totalPages;

  AllActivitiesState copyWith({
    List<RecentActivityModel>? items,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    String? roleFilter,
    String? topicFilter,
  }) {
    return AllActivitiesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      roleFilter: roleFilter ?? this.roleFilter,
      topicFilter: topicFilter ?? this.topicFilter,
    );
  }
}

class AllActivitiesNotifier extends StateNotifier<AllActivitiesState> {
  AllActivitiesNotifier() : super(const AllActivitiesState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await homeRepository.getPaginatedActivities(
        page: 1,
        size: 15,
        role: state.roleFilter,
        topic: state.topicFilter,
      );
      if (res.success && res.data != null) {
        final data = res.data!;
        state = state.copyWith(
          items: data.items,
          currentPage: data.currentPage,
          totalPages: data.totalPages,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message.isNotEmpty ? res.message : 'Error',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (state.isLoading || state.isFetchingMore || !state.hasMore) return;

    state = state.copyWith(isFetchingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await homeRepository.getPaginatedActivities(
        page: nextPage,
        size: 15,
        role: state.roleFilter,
        topic: state.topicFilter,
      );
      if (res.success && res.data != null) {
        final data = res.data!;
        state = state.copyWith(
          items: [...state.items, ...data.items],
          currentPage: data.currentPage,
          totalPages: data.totalPages,
          isFetchingMore: false,
        );
      } else {
        state = state.copyWith(isFetchingMore: false);
      }
    } catch (_) {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  void setRoleFilter(String role) {
    if (state.roleFilter == role) return;
    state = state.copyWith(roleFilter: role);
    fetchInitial();
  }

  void setTopicFilter(String topic) {
    if (state.topicFilter == topic) return;
    state = state.copyWith(topicFilter: topic);
    fetchInitial();
  }

  Future<void> refresh() async {
    await fetchInitial();
  }
}

final allActivitiesProvider =
    StateNotifierProvider.autoDispose<AllActivitiesNotifier, AllActivitiesState>(
  (ref) => AllActivitiesNotifier(),
);
