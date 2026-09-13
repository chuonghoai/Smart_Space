import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class MyReportsState {
  /// Dữ liệu gốc
  final List<ReportModel> summaryReports;

  /// Dữ liệu hiển thị - thay đổi theo filter
  final List<ReportModel> displayReports;

  final bool isLoading;
  final String? error;
  final ReportStatus? currentFilter; // null for 'All'

  MyReportsState({
    this.summaryReports = const [],
    this.displayReports = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter,
  });

  MyReportsState copyWith({
    List<ReportModel>? summaryReports,
    List<ReportModel>? displayReports,
    bool? isLoading,
    String? error,
    ReportStatus? currentFilter,
    bool clearError = false,
  }) {
    return MyReportsState(
      summaryReports: summaryReports ?? this.summaryReports,
      displayReports: displayReports ?? this.displayReports,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  // To allow clearing the filter
  MyReportsState clearFilter() {
    return MyReportsState(
      summaryReports: summaryReports,
      displayReports: summaryReports, // Reset về danh sách gốc
      isLoading: isLoading,
      error: error,
      currentFilter: null,
    );
  }

  // Summary Card
  int get totalCount => summaryReports.length;
  int get processingCount =>
      summaryReports.where((r) => r.status == ReportStatus.processing).length;
  int get processedCount =>
      summaryReports.where((r) => r.status == ReportStatus.processed).length;

  //  Phân nhóm theo thời gian (dùng displayReports - ĐỔI khi filter)
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

    for (var report in displayReports) {
      final reportDate = DateTime(
        report.createdAt.year,
        report.createdAt.month,
        report.createdAt.day,
      );
      if (reportDate.isAtSameMomentAs(today)) {
        groups['today']!.add(report);
      } else if (reportDate.isAfter(startOfWeek) ||
          reportDate.isAtSameMomentAs(startOfWeek)) {
        groups['thisWeek']!.add(report);
      } else {
        groups['older']!.add(report);
      }
    }

    // Sort each group by latest first
    groups['today']!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    groups['thisWeek']!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    groups['older']!.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return groups;
  }
}

class MyReportsNotifier extends StateNotifier<MyReportsState> {
  final ReportService _service;

  MyReportsNotifier(this._service) : super(MyReportsState()) {
    _initLoad();
  }

  /// Lần đầu mở trang: load tất cả → vừa làm Summary vừa làm danh sách hiển thị
  Future<void> _initLoad() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getMyReports();
      if (response.success && response.data != null) {
        state = state.copyWith(
          summaryReports: response.data!,
          displayReports: response.data!,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Khi user đổi filter → chỉ load lại danh sách hiển thị, KHÔNG đụng Summary
  void setFilter(ReportStatus? status) {
    if (status == null) {
      state = state.clearFilter();
      _fetchDisplayReports();
    } else {
      state = state.copyWith(currentFilter: status);
      _fetchDisplayReports(statusFilter: status);
    }
  }

  /// Fetch chỉ dùng cho danh sách hiển thị (không ghi đè summaryReports)
  Future<void> _fetchDisplayReports({ReportStatus? statusFilter}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final statusParam = statusFilter?.name;
      final response = await _service.getMyReports(status: statusParam);
      if (response.success && response.data != null) {
        state = state.copyWith(
          displayReports: response.data!,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Pull-to-refresh: load lại cả Summary + danh sách
  Future<void> refresh() async {
    state = state.copyWith(currentFilter: null);
    await _initLoad();
  }
}

final myReportsProvider =
    StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
      return MyReportsNotifier(reportService);
    });
