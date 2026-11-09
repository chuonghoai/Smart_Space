import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/my_reports_page_model.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class MyReportsState {
  /// Số liệu thẻ tổng hợp — backend đếm trên toàn bộ phản ánh, không phụ thuộc bộ lọc/tìm kiếm.
  final MyReportsSummary summary;

  /// Các trang đã tải của bộ lọc + từ khoá hiện tại (mới nhất trước).
  final List<ReportModel> reports;

  /// Giá trị `status` gửi lên API; null = Tất cả. Ngoài [ReportStatus] còn có 'rehandling'.
  final String? statusFilter;
  final EReportSeverity? severityFilter;

  /// Khoảng ngày tạo; null = mọi thời gian.
  final ReportDateRange? dateRangeFilter;
  final String searchQuery;

  final int page;
  final bool hasMore;

  /// Tổng số phản ánh khớp bộ lọc hiện tại (mọi trang).
  final int totalElements;

  /// Đã hoàn tất lần tải đầu tiên (thành công hoặc lỗi).
  final bool hasLoaded;

  /// Đang tải trang 1 (mở màn, làm mới, đổi bộ lọc/từ khoá).
  final bool isLoading;
  final bool isLoadingMore;

  /// Lỗi khi tải trang 1.
  final String? error;

  const MyReportsState({
    this.summary = const MyReportsSummary(),
    this.reports = const [],
    this.statusFilter,
    this.severityFilter,
    this.dateRangeFilter,
    this.searchQuery = '',
    this.page = 0,
    this.hasMore = false,
    this.totalElements = 0,
    this.hasLoaded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get isFiltering =>
      statusFilter != null || severityFilter != null || dateRangeFilter != null || searchQuery.isNotEmpty;

  /// Các field lọc nullable và [error] nhận function để có thể gán `null` tường minh.
  MyReportsState copyWith({
    MyReportsSummary? summary,
    List<ReportModel>? reports,
    String? Function()? statusFilter,
    EReportSeverity? Function()? severityFilter,
    ReportDateRange? Function()? dateRangeFilter,
    String? searchQuery,
    int? page,
    bool? hasMore,
    int? totalElements,
    bool? hasLoaded,
    bool? isLoading,
    bool? isLoadingMore,
    String? Function()? error,
  }) {
    return MyReportsState(
      summary: summary ?? this.summary,
      reports: reports ?? this.reports,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      severityFilter: severityFilter != null ? severityFilter() : this.severityFilter,
      dateRangeFilter: dateRangeFilter != null ? dateRangeFilter() : this.dateRangeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalElements: totalElements ?? this.totalElements,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error != null ? error() : this.error,
    );
  }

  /// Phân nhóm theo thời gian. [reports] đã sắp xếp mới nhất trước nên thứ tự trong nhóm được giữ nguyên.
  Map<String, List<ReportModel>> get groupedReports {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Đầu tuần (Thứ Hai)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final Map<String, List<ReportModel>> groups = {
      'today': [],
      'thisWeek': [],
      'older': [],
    };

    for (final report in reports) {
      final reportDate = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      if (reportDate.isAtSameMomentAs(today)) {
        groups['today']!.add(report);
      } else if (!reportDate.isBefore(startOfWeek)) {
        groups['thisWeek']!.add(report);
      } else {
        groups['older']!.add(report);
      }
    }
    return groups;
  }
}

class MyReportsNotifier extends StateNotifier<MyReportsState> {
  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final ReportService _service;
  Timer? _debounce;

  /// Tăng mỗi lần tải lại trang 1 — response của lần tải cũ hơn bị bỏ qua.
  int _requestId = 0;

  MyReportsNotifier(this._service) : super(const MyReportsState()) {
    refresh();
  }

  /// Mở màn / kéo làm mới / sau khi sửa-huỷ: tải lại tổng hợp + trang 1, GIỮ bộ lọc & từ khoá hiện tại.
  Future<void> refresh() async {
    _debounce?.cancel();
    await Future.wait([_loadSummary(), _loadFirstPage()]);
  }

  /// Đổi chip lọc (null = Tất cả) → chỉ tải lại danh sách, không đụng tổng hợp.
  void setFilter(String? status) {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: () => status);
    _loadFirstPage(clearList: true);
  }

  void setSeverity(EReportSeverity? severity) {
    if (severity == state.severityFilter) return;
    state = state.copyWith(severityFilter: () => severity);
    _loadFirstPage(clearList: true);
  }

  /// Khoảng ngày tạo (null = mọi thời gian).
  void setDateRange(ReportDateRange? range) {
    if (range == state.dateRangeFilter) return;
    state = state.copyWith(dateRangeFilter: () => range);
    _loadFirstPage(clearList: true);
  }

  /// Bỏ trạng thái, mức độ, khoảng ngày và từ khoá.
  void clearFilters() {
    _debounce?.cancel();
    if (!state.isFiltering) return;
    state = state.copyWith(
      statusFilter: () => null,
      severityFilter: () => null,
      dateRangeFilter: () => null,
      searchQuery: '',
    );
    _loadFirstPage(clearList: true);
  }

  /// Tìm kiếm theo tiêu đề / mô tả / địa chỉ, debounce để không gọi API mỗi phím gõ.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final keyword = query.trim();
      if (keyword == state.searchQuery) return;
      state = state.copyWith(searchQuery: keyword);
      _loadFirstPage(clearList: true);
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final requestId = _requestId;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _service.getMyReports(
        status: state.statusFilter,
        severity: state.severityFilter,
        dateRange: state.dateRangeFilter,
        search: state.searchQuery,
        page: nextPage,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      if (!res.success || res.data == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }
      // Bỏ bản ghi trùng khi dữ liệu bị dịch trang (vd. vừa tạo phản ánh mới giữa 2 lần tải)
      final loadedIds = state.reports.map((r) => r.id).toSet();
      state = state.copyWith(
        reports: [
          ...state.reports,
          ...res.data!.items.where((r) => !loadedIds.contains(r.id)),
        ],
        page: nextPage,
        hasMore: nextPage < res.data!.totalPages,
        totalElements: res.data!.totalElements,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _service.getMyReportsSummary();
      if (!mounted) return;
      if (res.success && res.data != null) {
        state = state.copyWith(summary: res.data);
      }
    } catch (_) {
      // Giữ số liệu cũ; lỗi danh sách (nếu có) đã được hiển thị riêng.
    }
  }

  /// [clearList] = true khi đổi bộ lọc/từ khoá để không hiển thị dữ liệu của bộ lọc cũ trong lúc chờ.
  Future<void> _loadFirstPage({bool clearList = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(
      reports: clearList ? const [] : null,
      isLoading: true,
      isLoadingMore: false,
      error: () => null,
    );
    try {
      final res = await _service.getMyReports(
        status: state.statusFilter,
        severity: state.severityFilter,
        dateRange: state.dateRangeFilter,
        search: state.searchQuery,
        page: 1,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      if (!res.success || res.data == null) {
        state = state.copyWith(isLoading: false, hasLoaded: true, error: () => res.message);
        return;
      }
      state = state.copyWith(
        reports: res.data!.items,
        page: 1,
        hasMore: 1 < res.data!.totalPages,
        totalElements: res.data!.totalElements,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, hasLoaded: true, error: () => e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final myReportsProvider =
    StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
      return MyReportsNotifier(reportService);
    });
