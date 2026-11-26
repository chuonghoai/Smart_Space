import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:mobile_shared/features/sos/services/sos_ws_service.dart';

import '../data/sos_admin_repository.dart';

/// Trùng giới hạn ghi chú ở backend (ResolveSosRequest.note).
const int kSosMaxNoteLength = 500;

enum SosFilter {
  open('open'),
  resolved('resolved');

  final String apiValue;
  const SosFilter(this.apiValue);
}

class SosListState {
  final List<SosAlertModel> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const SosListState({
    this.items = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalElements = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage < totalPages;

  SosListState copyWith({
    List<SosAlertModel>? items,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return SosListState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SosListNotifier extends StateNotifier<SosListState> {
  final SosFilter filter;

  SosListNotifier(this.filter) : super(const SosListState(isLoading: true)) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: state.items.isEmpty, clearError: true);
    final res = await sosAdminRepository.list(status: filter.apiValue, page: 1);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final page = res.data!;
      state = SosListState(
        items: page.items,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        totalElements: page.totalElements,
      );
    } else {
      state = state.copyWith(isLoading: false, error: res.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final res = await sosAdminRepository.list(status: filter.apiValue, page: nextPage);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final page = res.data!;
      final seen = state.items.map((e) => e.id).toSet();
      final merged = [...state.items, ...page.items.where((e) => !seen.contains(e.id))];
      state = state.copyWith(
        items: merged,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        totalElements: page.totalElements,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

// Kiểu khai báo tường minh: các provider dưới đây và sosRealtimeSyncProvider tham chiếu lẫn nhau
final AutoDisposeStateNotifierProviderFamily<SosListNotifier, SosListState, SosFilter> sosListProvider =
    StateNotifierProvider.autoDispose.family<SosListNotifier, SosListState, SosFilter>((ref, filter) {
  ref.watch(sosRealtimeSyncProvider);
  return SosListNotifier(filter);
});

final AutoDisposeFutureProviderFamily<SosAlertModel, String> sosDetailProvider =
    FutureProvider.autoDispose.family<SosAlertModel, String>((ref, id) async {
  ref.watch(sosRealtimeSyncProvider);
  final res = await sosAdminRepository.detail(id);
  if (res.success && res.data != null) return res.data!;
  throw Exception(res.message);
});

final AutoDisposeFutureProvider<int> sosOpenCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(sosRealtimeSyncProvider);
  final res = await sosAdminRepository.openCount();
  return res.success ? (res.data ?? 0) : 0;
});

/// Nghe /user/queue/sos: có sự kiện thì làm mới danh sách, số đếm và chi tiết SOS liên quan.
final AutoDisposeProvider<void> sosRealtimeSyncProvider = Provider.autoDispose<void>((ref) {
  final sub = sosWsService.events.listen((event) {
    ref.invalidate(sosListProvider);
    ref.invalidate(sosOpenCountProvider);
    ref.invalidate(sosDetailProvider(event.sos.id));
  });
  ref.onDispose(sub.cancel);
});

/// Thao tác của admin; trả về thông báo lỗi hoặc null khi thành công.
class SosAdminActions {
  final Ref _ref;

  SosAdminActions(this._ref);

  Future<String?> acknowledge(String id) async {
    final res = await sosAdminRepository.acknowledge(id);
    _refresh(id);
    return res.success ? null : res.message;
  }

  Future<String?> resolve(String id, {required bool falseAlarm, String? note}) async {
    final res = await sosAdminRepository.resolve(id, falseAlarm: falseAlarm, note: note);
    _refresh(id);
    return res.success ? null : res.message;
  }

  void _refresh(String id) {
    _ref.invalidate(sosListProvider);
    _ref.invalidate(sosOpenCountProvider);
    _ref.invalidate(sosDetailProvider(id));
  }
}

final sosAdminActionsProvider = Provider<SosAdminActions>((ref) => SosAdminActions(ref));
