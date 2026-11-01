import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/services/delegation_service.dart';
import 'package:smartspace_staff/features/reports/providers/report_detail_provider.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_wallet_provider.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';

/// Service nhờ làm giùm — tách thành provider để test thay bằng repo giả.
final delegationServiceProvider = Provider<DelegationService>((ref) => delegationService);

/// Id staff đang đăng nhập — để biết mình là người nhờ hay người được nhờ / người được giao.
final currentStaffIdProvider = FutureProvider<String?>((ref) async {
  final user = await userStorageService.getUser();
  return user?.id;
});

/// Trạng thái nhờ làm giùm của report (màn chi tiết): nhờ được không, bonus dự kiến, yêu cầu đang hoạt động.
final delegationReportStateProvider = FutureProvider.autoDispose.family<DelegationReportStateModel, String>((
  ref,
  reportId,
) async {
  final response = await ref.read(delegationServiceProvider).getReportState(reportId);
  final data = response.data;
  if (!response.success || data == null) throw Exception(response.message);
  return data;
});

// ===================== Danh sách phân trang (dùng chung) =====================

class PagedState<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PagedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Tải trang đầu / trang kế; response trễ của lần tải cũ (vd. gõ tìm kiếm nhanh) bị bỏ qua.
mixin _PagedLoader<T> {
  int _generation = 0;

  PagedState<T> get pagedState;
  set pagedState(PagedState<T> value);

  Future<ApiResponse<DelegationPage<T>>> fetchPage(int page);

  Future<void> loadFirst() async {
    final generation = ++_generation;
    pagedState = pagedState.copyWith(isLoading: true, clearError: true);
    final response = await fetchPage(0);
    if (generation != _generation) return;
    final data = response.data;
    pagedState = response.success && data != null
        ? PagedState<T>(items: data.items, page: data.page, hasMore: data.hasMore)
        : pagedState.copyWith(isLoading: false, error: response.message);
  }

  Future<void> loadMore() async {
    final current = pagedState;
    if (current.isLoading || current.isLoadingMore || !current.hasMore) return;
    final generation = _generation;
    pagedState = current.copyWith(isLoadingMore: true);
    final response = await fetchPage(current.page + 1);
    if (generation != _generation) return;
    final data = response.data;
    pagedState = response.success && data != null
        ? pagedState.copyWith(
            items: [...pagedState.items, ...data.items],
            page: data.page,
            hasMore: data.hasMore,
            isLoadingMore: false,
          )
        : pagedState.copyWith(isLoadingMore: false, error: response.message);
  }
}

/// Danh sách yêu cầu theo hộp (nhận được / đã gửi).
class DelegationListNotifier extends AutoDisposeFamilyNotifier<PagedState<DelegationModel>, DelegationBox>
    with _PagedLoader<DelegationModel> {
  @override
  PagedState<DelegationModel> build(DelegationBox arg) {
    Future.microtask(loadFirst);
    return const PagedState(isLoading: true);
  }

  @override
  PagedState<DelegationModel> get pagedState => state;

  @override
  set pagedState(PagedState<DelegationModel> value) => state = value;

  @override
  Future<ApiResponse<DelegationPage<DelegationModel>>> fetchPage(int page) =>
      ref.read(delegationServiceProvider).list(arg, page: page);
}

final delegationListProvider = NotifierProvider.autoDispose
    .family<DelegationListNotifier, PagedState<DelegationModel>, DelegationBox>(DelegationListNotifier.new);

/// Tìm đồng nghiệp để nhờ, gõ tìm kiếm có debounce.
class ColleagueSearchNotifier extends AutoDisposeNotifier<PagedState<ColleagueModel>>
    with _PagedLoader<ColleagueModel> {
  static const Duration debounce = Duration(milliseconds: 350);

  String _query = '';
  Timer? _debounceTimer;

  @override
  PagedState<ColleagueModel> build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    Future.microtask(loadFirst);
    return const PagedState(isLoading: true);
  }

  @override
  PagedState<ColleagueModel> get pagedState => state;

  @override
  set pagedState(PagedState<ColleagueModel> value) => state = value;

  @override
  Future<ApiResponse<DelegationPage<ColleagueModel>>> fetchPage(int page) =>
      ref.read(delegationServiceProvider).searchColleagues(query: _query, page: page);

  void search(String query) {
    final normalized = query.trim();
    if (normalized == _query) return;
    _query = normalized;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, loadFirst);
  }
}

final colleagueSearchProvider = NotifierProvider.autoDispose<ColleagueSearchNotifier, PagedState<ColleagueModel>>(
  ColleagueSearchNotifier.new,
);

// ===================== Thao tác =====================

/// Gửi / nhận / từ chối / huỷ yêu cầu, rồi làm mới các màn bị ảnh hưởng (chi tiết report, ví, danh sách, Home).
/// Trả về null khi thành công, ngược lại là thông báo lỗi từ backend.
class DelegationActions {
  final Ref _ref;

  DelegationActions(this._ref);

  DelegationService get _service => _ref.read(delegationServiceProvider);

  Future<String?> request({required String reportId, required String helperId, String? note}) =>
      _run(reportId, () => _service.create(reportId: reportId, helperId: helperId, note: note));

  Future<String?> accept(DelegationModel delegation) => _run(delegation.reportId, () => _service.accept(delegation.id));

  Future<String?> decline(DelegationModel delegation) =>
      _run(delegation.reportId, () => _service.decline(delegation.id));

  Future<String?> cancel(DelegationModel delegation) => _run(delegation.reportId, () => _service.cancel(delegation.id));

  Future<String?> _run(String reportId, Future<ApiResponse<DelegationModel>> Function() action) async {
    try {
      final response = await action();
      if (!response.success) return response.message;
    } catch (e) {
      return e.toString();
    }
    // Thất bại thì giữ nguyên màn hiện tại; thành công mới làm mới
    _ref.invalidate(delegationReportStateProvider(reportId));
    _ref.invalidate(delegationListProvider);
    unawaited(_ref.read(reportDetailProvider(reportId).notifier).refresh().catchError((_) {}));
    unawaited(_ref.read(staffWalletProvider.notifier).refresh());
    unawaited(_ref.read(homeControllerProvider.notifier).manualRefresh());
    return null;
  }
}

final delegationActionsProvider = Provider<DelegationActions>(DelegationActions.new);
