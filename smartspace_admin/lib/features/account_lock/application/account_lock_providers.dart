import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';

import '../data/account_lock_repository.dart';
import '../models/account_lock_request_model.dart';

/// Số admin khác cần bảo lãnh và thời hạn biểu quyết — khớp với backend
/// (AccountLockRequestServiceImpl). Backend vẫn là nơi quyết định cuối cùng.
const int kLockRequiredApprovals = 2;
const int kLockVotingHours = 72;
const int kLockMaxEvidenceImages = 5;
const int kLockMinReasonLength = 20;
const int kLockMaxReasonLength = 2000;
const int kUnlockMinReasonLength = 10;
const int kUnlockMaxReasonLength = 500;

/// Hàng chờ còn dưới ngưỡng này → đồng hồ biểu quyết chuyển đỏ (tín hiệu đỏ duy nhất của đề xuất).
const Duration kLockUrgentThreshold = Duration(hours: 12);

/// Bộ lọc danh sách đề xuất (cũng là ba thẻ đếm phía trên danh sách).
enum LockRequestFilter {
  awaitingMine('awaiting_mine'),
  pending('pending'),
  resolved('resolved');

  final String apiValue;
  const LockRequestFilter(this.apiValue);
}

class LockRequestListState {
  final List<AccountLockRequestModel> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// Thời điểm lấy dữ liệu — hiển thị "Cập nhật lúc …" cạnh nút làm mới.
  final DateTime fetchedAt;

  LockRequestListState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get hasMore => currentPage < totalPages;

  LockRequestListState copyWith({
    List<AccountLockRequestModel>? items,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return LockRequestListState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      fetchedAt: fetchedAt,
    );
  }
}

/// Danh sách đề xuất theo bộ lọc, tải thêm khi cuộn (dùng chung web + mobile).
class LockRequestListNotifier
    extends AutoDisposeFamilyAsyncNotifier<LockRequestListState, LockRequestFilter> {
  static const int _pageSize = 10;

  @override
  Future<LockRequestListState> build(LockRequestFilter filter) => _fetchPage(1);

  Future<LockRequestListState> _fetchPage(int page) async {
    final response = await accountLockRepository.getRequests(
      status: arg.apiValue,
      page: page,
      size: _pageSize,
    );
    if (response.success && response.data != null) {
      final data = response.data!;
      return LockRequestListState(
        items: data.items,
        currentPage: data.currentPage,
        totalPages: data.totalPages,
      );
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(() => _fetchPage(1));
    state = result;
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

final lockRequestListProvider = AsyncNotifierProvider.autoDispose
    .family<LockRequestListNotifier, LockRequestListState, LockRequestFilter>(
      LockRequestListNotifier.new,
    );

final lockRequestDetailProvider = FutureProvider.autoDispose
    .family<AccountLockRequestModel, String>((ref, id) async {
      final response = await accountLockRepository.getRequest(id);
      if (response.success && response.data != null) return response.data!;
      throw Exception(response.message);
    });

/// Badge trên tab "Đề xuất khoá" (số đề xuất cần admin đang xem bỏ phiếu).
final lockPendingCountProvider =
    FutureProvider.autoDispose<AccountLockPendingCount>((ref) async {
      final response = await accountLockRepository.getPendingCount();
      if (response.success && response.data != null) return response.data!;
      throw Exception(response.message);
    });

/// Kết quả tạo đề xuất: [requestId] khi thành công, ngược lại [error] (có thể rỗng).
typedef LockCreateResult = ({String? requestId, String? error});

/// Thao tác ghi. Mỗi hàm trả `null` khi thành công, ngược lại là message lỗi từ backend
/// (có thể rỗng → UI dùng thông báo mặc định). Sau khi thành công tự làm mới dữ liệu liên quan.
class AccountLockActions {
  final Ref _ref;

  AccountLockActions(this._ref);

  Future<LockCreateResult> create({
    required String targetUserId,
    required String reason,
    required List<String> evidenceImageUrls,
    required List<String> reportIds,
  }) async {
    final response = await accountLockRepository.create(
      targetUserId: targetUserId,
      reason: reason,
      evidenceImageUrls: evidenceImageUrls,
      reportIds: reportIds,
    );
    if (!response.success || response.data == null) {
      return (requestId: null, error: response.message);
    }
    _ref.invalidate(userDetailProvider(targetUserId));
    _invalidateLists();
    return (requestId: response.data!.id, error: null);
  }

  Future<String?> vote(AccountLockRequestModel request, {required bool approve, String? comment}) async {
    final response = await accountLockRepository.vote(request.id, approve: approve, comment: comment);
    if (!response.success) return response.message;
    _afterRequestChanged(request);
    // Có thể vừa khóa tài khoản → danh sách người dùng đổi trạng thái
    _ref.invalidate(userListProvider);
    return null;
  }

  Future<String?> cancel(AccountLockRequestModel request) async {
    final response = await accountLockRepository.cancel(request.id);
    if (!response.success) return response.message;
    _afterRequestChanged(request);
    return null;
  }

  Future<String?> unlockUser(String userId, String reason) async {
    final response = await accountLockRepository.unlockUser(userId, reason);
    if (!response.success) return response.message;
    _ref.invalidate(userDetailProvider(userId));
    _ref.invalidate(userListProvider);
    return null;
  }

  void _afterRequestChanged(AccountLockRequestModel request) {
    _ref.invalidate(lockRequestDetailProvider(request.id));
    _ref.invalidate(userDetailProvider(request.target.id));
    _invalidateLists();
  }

  void _invalidateLists() {
    _ref.invalidate(lockRequestListProvider);
    _ref.invalidate(lockPendingCountProvider);
  }
}

/// Không autoDispose: widget gọi qua `ref.read` rồi `await`, provider phải còn sống để
/// invalidate sau khi request trả về.
final accountLockActionsProvider = Provider<AccountLockActions>(
  (ref) => AccountLockActions(ref),
);
