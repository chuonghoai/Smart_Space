import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_repository.dart';
import '../models/admin_user_model.dart';
import '../models/user_detail_model.dart';
import '../models/user_statistics_model.dart';
import '../models/user_trend_model.dart';

/// Sort hợp lệ của API `/admin/users`.
enum UserSort {
  newest('newest'),
  oldest('oldest'),
  name('name');

  final String apiValue;
  const UserSort(this.apiValue);
}

class UserListState {
  final List<AdminUserModel> users;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final String? search;
  final UserSort sort;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  const UserListState({
    required this.users,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    this.search,
    this.sort = UserSort.newest,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  bool get hasMore => currentPage < totalPages;

  UserListState copyWith({
    List<AdminUserModel>? users,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return UserListState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      search: search,
      sort: sort,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

/// Danh sách người dùng. Web dùng [goToPage] (thay trang),
/// Mobile dùng [loadMore] (nối thêm trang — infinite scroll).
class UserListNotifier extends AutoDisposeAsyncNotifier<UserListState> {
  final int _pageSize = 10;
  int _page = 1;
  String? _search;
  UserSort _sort = UserSort.newest;
  Timer? _debounce;

  // Tăng mỗi lần đổi query → bỏ qua response cũ trả về muộn
  int _generation = 0;

  @override
  Future<UserListState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    _generation++;
    return _fetchPage(_page);
  }

  Future<UserListState> _fetchPage(int page) async {
    final response = await userRepository.getUsers(
      page: page,
      size: _pageSize,
      search: _search,
      sort: _sort.apiValue,
    );
    if (response.success && response.data != null) {
      final data = response.data!;
      return UserListState(
        users: data.users,
        currentPage: data.currentPage,
        pageSize: data.pageSize,
        totalPages: data.totalPages,
        totalElements: data.totalElements,
        search: _search,
        sort: _sort,
      );
    }
    throw Exception(response.message);
  }

  /// Pull-to-refresh: giữ dữ liệu cũ trên màn hình cho tới khi có kết quả mới.
  Future<void> refresh() async {
    _page = 1;
    final generation = ++_generation;
    final result = await AsyncValue.guard(() => _fetchPage(_page));
    if (generation == _generation) state = result;
  }

  void setSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final normalized = query.trim();
      final next = normalized.isEmpty ? null : normalized;
      if (next == _search) return;
      _search = next;
      _page = 1;
      ref.invalidateSelf();
    });
  }

  void setSort(UserSort sort) {
    if (sort == _sort) return;
    _sort = sort;
    _page = 1;
    ref.invalidateSelf();
  }

  void goToPage(int page) {
    final totalPages = state.valueOrNull?.totalPages ?? 1;
    if (page < 1 || page > totalPages || page == _page) return;
    _page = page;
    ref.invalidateSelf();
  }

  /// Sau khi lỗi, chỉ tải lại khi người dùng chủ động bấm thử lại ([retry]),
  /// tránh scroll listener gọi API liên tục.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasMore ||
        (current.loadMoreFailed && !retry)) {
      return;
    }

    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );

    try {
      final next = await _fetchPage(current.currentPage + 1);
      if (generation != _generation) return;
      _page = next.currentPage;
      state = AsyncData(
        current.copyWith(
          users: [...current.users, ...next.users],
          currentPage: next.currentPage,
          totalPages: next.totalPages,
          totalElements: next.totalElements,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

final userListProvider =
    AutoDisposeAsyncNotifierProvider<UserListNotifier, UserListState>(
      () => UserListNotifier(),
    );

final userStatisticsProvider = FutureProvider.autoDispose<UserStatisticsModel>((
  ref,
) {
  return userRepository.getStatistics();
});

/// period: 'daily' | 'weekly' | 'monthly'
final userTrendProvider = FutureProvider.autoDispose
    .family<List<UserTrendItem>, String>((ref, period) {
      return userRepository.getRegistrationTrend(period);
    });

final userDetailProvider = FutureProvider.autoDispose
    .family<UserDetailModel, String>((ref, userId) {
      return userRepository.getUserDetail(userId);
    });
