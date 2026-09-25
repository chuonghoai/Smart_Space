import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_repository.dart';
import '../models/report_filter_model.dart';
import '../models/report_list_model.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

final reportFilterProvider = StateProvider<ReportFilter>(
  (ref) => const ReportFilter(),
);

// ── Table / paginated list ────────────────────────────────────────────────────

final reportListProvider =
    AsyncNotifierProvider<ReportListNotifier, ReportListData>(
  ReportListNotifier.new,
);

class ReportListNotifier extends AsyncNotifier<ReportListData> {
  @override
  Future<ReportListData> build() async {
    final filter = ref.watch(reportFilterProvider);
    return _fetch(filter);
  }

  Future<ReportListData> _fetch(ReportFilter filter) async {
    final res = await reportRepository.getReportList(filter);
    if (res.success && res.data != null) return res.data!;
    throw Exception(res.message);
  }

  void setFilter(ReportFilter filter) =>
      ref.read(reportFilterProvider.notifier).state = filter;

  void setSearch(String search) {
    final f = ref.read(reportFilterProvider);
    ref.read(reportFilterProvider.notifier).state =
        f.copyWith(search: search, page: 1);
  }

  void setPage(int page) {
    final f = ref.read(reportFilterProvider);
    ref.read(reportFilterProvider.notifier).state = f.copyWith(page: page);
  }

  /// Optimistically absent — used after Kanban update to refresh full list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _fetch(ref.read(reportFilterProvider)));
  }

  /// Update status via API; returns true on success.
  Future<bool> updateStatus(String reportId, String newStatus) async {
    final res =
        await reportRepository.updateReportStatus(reportId, newStatus);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }
}

// ── Kanban column ─────────────────────────────────────────────────────────────

class KanbanColumnData {
  final List<ReportListItem> items;
  final int currentPage;
  final bool hasMore;

  const KanbanColumnData({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });
}

final kanbanColumnProvider = AsyncNotifierProviderFamily<KanbanColumnNotifier,
    KanbanColumnData, String>(
  KanbanColumnNotifier.new,
);

class KanbanColumnNotifier
    extends FamilyAsyncNotifier<KanbanColumnData, String> {
  // arg = status string (pending / processing / processed / rejected)

  @override
  Future<KanbanColumnData> build(String arg) => _fetch(1, []);

  Future<KanbanColumnData> _fetch(int page, List<ReportListItem> existing) async {
    final filter = ReportFilter(status: arg, page: page);
    final res = await reportRepository.getReportList(filter);
    if (res.success && res.data != null) {
      final data = res.data!;
      return KanbanColumnData(
        items: [...existing, ...data.items],
        currentPage: page,
        hasMore: data.hasNextPage,
      );
    }
    throw Exception(res.message);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = await _fetch(current.currentPage + 1, current.items);
    state = AsyncData(next);
  }

  /// Optimistic remove (when dragging away).
  void removeItem(String reportId) {
    state = state.whenData((d) => KanbanColumnData(
          items: d.items.where((r) => r.id != reportId).toList(),
          currentPage: d.currentPage,
          hasMore: d.hasMore,
        ));
  }

  /// Optimistic add (when dropping here). newStatus already set externally.
  void addItem(ReportListItem item) {
    state = state.whenData((d) => KanbanColumnData(
          items: [item, ...d.items],
          currentPage: d.currentPage,
          hasMore: d.hasMore,
        ));
  }
}
