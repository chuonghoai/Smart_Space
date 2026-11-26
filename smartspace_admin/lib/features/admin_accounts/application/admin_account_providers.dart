import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/home/data/home_repository.dart';
import 'package:smartspace_admin/features/home/models/recent_activity_model.dart';

import '../data/admin_account_repository.dart';
import '../models/admin_account_list_response.dart';
import '../models/admin_account_model.dart';

class AdminAccountListState {
  final AdminAccountSummary summary;
  final List<AdminAccountModel> admins;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final String? search;
  final String? status;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  const AdminAccountListState({
    required this.summary,
    required this.admins,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    this.search,
    this.status,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  bool get hasMore => currentPage < totalPages;

  /// Còn đúng một admin hoạt động → không được khóa thêm (backend cũng chặn).
  bool get isLastActiveAdmin => summary.active <= 1;

  /// Có thể khóa/mở khóa [admin] không — UI dùng để disable nút kèm giải thích.
  bool canToggle(AdminAccountModel admin) =>
      !admin.isCurrentUser && !(admin.isActive && isLastActiveAdmin);

  AdminAccountListState copyWith({
    AdminAccountSummary? summary,
    List<AdminAccountModel>? admins,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return AdminAccountListState(
      summary: summary ?? this.summary,
      admins: admins ?? this.admins,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      search: search,
      status: status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

/// Bộ lọc trạng thái đang chọn: 'all' | 'active' | 'blocked'.
/// Nguồn sự thật duy nhất cho dropdown (web), filter sheet (mobile) và badge thống kê.
final adminStatusFilterProvider = StateProvider.autoDispose<String>((_) => 'all');

/// Danh sách quản trị viên. Web dùng [goToPage] (thay trang),
/// Mobile dùng [loadMore] (nối thêm trang — infinite scroll).
class AdminAccountListNotifier
    extends AutoDisposeAsyncNotifier<AdminAccountListState> {
  final int _pageSize = 10;
  int _page = 1;
  String? _search;
  String? _status;
  Timer? _debounce;

  // Tăng mỗi lần đổi query → bỏ qua response cũ trả về muộn
  int _generation = 0;

  @override
  Future<AdminAccountListState> build() async {
    ref.onDispose(() => _debounce?.cancel());

    // Đổi bộ lọc → provider tự build lại; chỉ về trang 1 khi bộ lọc thực sự đổi
    final filter = ref.watch(adminStatusFilterProvider);
    final status = filter == 'all' ? null : filter;
    if (status != _status) {
      _status = status;
      _page = 1;
    }

    _generation++;
    return _fetchPage(_page);
  }

  Future<AdminAccountListState> _fetchPage(int page) async {
    final response = await adminAccountRepository.getAdmins(
      page: page,
      size: _pageSize,
      search: _search,
      status: _status,
    );
    if (response.success && response.data != null) {
      final data = response.data!;
      return AdminAccountListState(
        summary: data.summary,
        admins: data.admins,
        currentPage: data.currentPage,
        totalPages: data.totalPages,
        totalElements: data.totalElements,
        search: _search,
        status: _status,
      );
    }
    throw Exception(response.message);
  }

  /// Pull-to-refresh / thử lại: giữ dữ liệu cũ trên màn hình cho tới khi có kết quả mới.
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

  /// [status]: 'all' | 'active' | 'blocked' — [build] tự tải lại khi giá trị đổi.
  void setStatusFilter(String? status) {
    ref.read(adminStatusFilterProvider.notifier).state = status ?? 'all';
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
          summary: next.summary,
          admins: [...current.admins, ...next.admins],
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

  /// Tạo admin — backend tự sinh mật khẩu và gửi qua email.
  /// Trả về `null` khi thành công, ngược lại là message lỗi từ backend (có thể rỗng).
  Future<String?> createAdmin({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    final response = await adminAccountRepository.createAdmin(
      fullName: fullName,
      email: email,
      phone: phone,
    );
    if (response.success) {
      _page = 1;
      ref.invalidateSelf();
      return null;
    }
    return response.message;
  }

  /// Khóa / mở khóa. Trả về `null` khi thành công, ngược lại là message lỗi từ backend.
  Future<String?> toggleStatus(AdminAccountModel admin) async {
    final response = await adminAccountRepository.updateAdminStatus(
      admin.id,
      admin.isActive ? 'blocked' : 'active',
    );
    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(adminActivitiesProvider);
      ref.invalidate(adminActivityHistoryProvider);
      return null;
    }
    return response.message;
  }
}

final adminAccountListProvider = AutoDisposeAsyncNotifierProvider<
  AdminAccountListNotifier,
  AdminAccountListState
>(() => AdminAccountListNotifier());

/// Số hoạt động gần đây hiện sẵn trong panel chi tiết (bản đầy đủ: [adminActivityHistoryProvider]).
const int kAdminRecentActivityCount = 5;

/// Hoạt động gần đây do một admin thực hiện (tái sử dụng `/admin/activities?actorId=`).
final adminActivitiesProvider = FutureProvider.autoDispose
    .family<List<RecentActivityModel>, String>((ref, adminId) async {
      final response = await homeRepository.getPaginatedActivities(
        page: 1,
        size: kAdminRecentActivityCount,
        actorId: adminId,
      );
      if (response.success && response.data != null) {
        return response.data!.items;
      }
      throw Exception(response.message);
    });

class AdminActivityHistoryState {
  final List<RecentActivityModel> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  const AdminActivityHistoryState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  bool get hasMore => currentPage < totalPages;

  AdminActivityHistoryState copyWith({
    List<RecentActivityModel>? items,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return AdminActivityHistoryState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

/// Toàn bộ lịch sử hoạt động của một admin, tải thêm khi cuộn.
class AdminActivityHistoryNotifier
    extends AutoDisposeFamilyAsyncNotifier<AdminActivityHistoryState, String> {
  static const int _pageSize = 20;

  @override
  Future<AdminActivityHistoryState> build(String adminId) => _fetchPage(1);

  Future<AdminActivityHistoryState> _fetchPage(int page) async {
    final response = await homeRepository.getPaginatedActivities(
      page: page,
      size: _pageSize,
      actorId: arg,
    );
    if (response.success && response.data != null) {
      final data = response.data!;
      return AdminActivityHistoryState(
        items: data.items,
        currentPage: data.currentPage,
        totalPages: data.totalPages,
      );
    }
    throw Exception(response.message);
  }

  /// Sau khi lỗi, chỉ tải lại khi người dùng bấm thử lại ([retry]).
  Future<void> loadMore({bool retry = false}) async {
    final current = state.valueOrNull;
    if (current == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasMore ||
        (current.loadMoreFailed && !retry)) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final next = await _fetchPage(current.currentPage + 1);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.items],
          currentPage: next.currentPage,
          totalPages: next.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}

final adminActivityHistoryProvider = AsyncNotifierProvider.autoDispose
    .family<AdminActivityHistoryNotifier, AdminActivityHistoryState, String>(
      AdminActivityHistoryNotifier.new,
    );
