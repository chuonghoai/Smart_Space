import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_date_range.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';

class AllReportsState {
  /// Giá trị `status` của `GET /reports/staff/assigned`, mặc định.
  static const String allStatus = 'all';

  final List<ReportModel> reports;
  final bool isLoading;
  final bool hasMore;

  /// Giá trị `status` của API: 'all' | 'processing' | 'rehandling' | 'resolved'.
  final String filter;
  final ReportSeverity? severity;

  /// Từ khoá đã áp dụng (sau debounce), đã trim.
  final String search;
  final ReportDateRange? dateRange;
  final StaffReportSort sort;
  final int page;
  final String? error;
  final ReportStatisticsModel? stats;

  const AllReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.filter = allStatus,
    this.severity,
    this.search = '',
    this.dateRange,
    this.sort = StaffReportSort.latest,
    this.page = 0,
    this.error,
    this.stats,
  });

  /// Đang thu hẹp kết quả (khác mặc định). Thứ tự sắp xếp không thu hẹp nên không tính.
  bool get isFiltering =>
      filter != allStatus || severity != null || dateRange != null || search.isNotEmpty;

  /// [severity] và [dateRange] nhận function để có thể gán `null` tường minh.
  AllReportsState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? hasMore,
    String? filter,
    ReportSeverity? Function()? severity,
    String? search,
    ReportDateRange? Function()? dateRange,
    StaffReportSort? sort,
    int? page,
    String? error,
    ReportStatisticsModel? stats,
  }) {
    return AllReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      severity: severity != null ? severity() : this.severity,
      search: search ?? this.search,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class AllReportsController extends ChangeNotifier {
  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final ReportService _reportService;
  AllReportsState _state;
  Timer? _debounce;
  bool _disposed = false;

  /// Tăng mỗi lần bộ lọc đổi / tải lại; response của lần cũ về muộn thì bỏ qua.
  int _requestId = 0;

  AllReportsController({
    ReportService? service,
    String initialFilter = AllReportsState.allStatus,
  })  : _reportService = service ?? reportService,
        _state = AllReportsState(filter: initialFilter) {
    fetchInitial();
  }

  AllReportsState get state => _state;

  /// Tải lại trang đầu theo bộ lọc hiện tại. [refreshStats] = tải lại số đếm trạng thái
  /// (không phụ thuộc bộ lọc nên chỉ cần khi mở màn hình hoặc làm mới).
  Future<void> fetchInitial({bool refreshStats = true}) async {
    final requestId = ++_requestId;
    _state = _state.copyWith(isLoading: true, error: null, page: 0, reports: [], hasMore: true);
    _notify();

    try {
      final reportsFuture = _fetchPage(0);
      final statsFuture = refreshStats ? _reportService.getStaffStatistics() : null;
      final response = await reportsFuture;
      final statsResponse = await statsFuture;
      if (requestId != _requestId) return;

      if (response.success && response.data != null) {
        final newReports = response.data!;
        _state = _state.copyWith(
          reports: newReports,
          isLoading: false,
          hasMore: newReports.length == _pageSize,
          page: 1,
          stats: statsResponse != null && statsResponse.success ? statsResponse.data : null,
        );
      } else {
        _state = _state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (requestId != _requestId) return;
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (_state.isLoading || !_state.hasMore) return;

    final requestId = _requestId;
    _state = _state.copyWith(isLoading: true, error: null);
    _notify();

    try {
      final response = await _fetchPage(_state.page);
      if (requestId != _requestId) return;

      if (response.success && response.data != null) {
        final newReports = response.data!;
        _state = _state.copyWith(
          reports: [..._state.reports, ...newReports],
          isLoading: false,
          hasMore: newReports.length == _pageSize,
          page: _state.page + 1,
        );
      } else {
        _state = _state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (requestId != _requestId) return;
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    _notify();
  }

  void setFilter(String newFilter) {
    if (_state.filter == newFilter) return;
    _state = _state.copyWith(filter: newFilter);
    fetchInitial(refreshStats: false);
  }

  void setSeverity(ReportSeverity? severity) {
    if (_state.severity == severity) return;
    _state = _state.copyWith(severity: () => severity);
    fetchInitial(refreshStats: false);
  }

  void setDateRange(ReportDateRange? range) {
    if (_state.dateRange == range) return;
    _state = _state.copyWith(dateRange: () => range);
    fetchInitial(refreshStats: false);
  }

  void setSort(StaffReportSort sort) {
    if (_state.sort == sort) return;
    _state = _state.copyWith(sort: sort);
    fetchInitial(refreshStats: false);
  }

  /// Tìm theo tiêu đề / mô tả / địa chỉ, debounce để không gọi API mỗi phím gõ.
  void setSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final keyword = query.trim();
      if (_disposed || keyword == _state.search) return;
      _state = _state.copyWith(search: keyword);
      fetchInitial(refreshStats: false);
    });
  }

  /// Bỏ mọi bộ lọc thu hẹp (giữ thứ tự sắp xếp).
  void clearFilters() {
    _debounce?.cancel();
    if (!_state.isFiltering) return;
    _state = _state.copyWith(
      filter: AllReportsState.allStatus,
      severity: () => null,
      dateRange: () => null,
      search: '',
    );
    fetchInitial(refreshStats: false);
  }

  Future<ApiResponse<List<ReportModel>>> _fetchPage(int page) {
    return _reportService.getStaffAssignedReports(
      status: _state.filter,
      severity: _state.severity,
      search: _state.search,
      dateRange: _state.dateRange,
      sort: _state.sort,
      page: page,
      limit: _pageSize,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
