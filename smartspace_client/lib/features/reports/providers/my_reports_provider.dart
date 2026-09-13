import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class MyReportsState {
  final List<ReportModel> allReports;
  final bool isLoading;
  final String? error;
  final ReportStatus? currentFilter; // null for 'All'

  MyReportsState({
    this.allReports = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter,
  });

  MyReportsState copyWith({
    List<ReportModel>? allReports,
    bool? isLoading,
    String? error,
    ReportStatus? currentFilter,
    bool clearError = false,
  }) {
    return MyReportsState(
      allReports: allReports ?? this.allReports,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  // To allow clearing the filter
  MyReportsState clearFilter() {
    return MyReportsState(
      allReports: allReports,
      isLoading: isLoading,
      error: error,
      currentFilter: null,
    );
  }

  List<ReportModel> get filteredReports {
    if (currentFilter == null) return allReports;
    return allReports.where((r) => r.status == currentFilter).toList();
  }

  // Thống kê (Summary)
  int get totalCount => allReports.length;
  int get processingCount => allReports.where((r) => r.status == ReportStatus.processing).length;
  int get processedCount => allReports.where((r) => r.status == ReportStatus.processed).length;

  // Phân nhóm theo thời gian
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

    for (var report in filteredReports) {
      final reportDate = DateTime(report.createdAt.year, report.createdAt.month, report.createdAt.day);
      if (reportDate.isAtSameMomentAs(today)) {
        groups['today']!.add(report);
      } else if (reportDate.isAfter(startOfWeek) || reportDate.isAtSameMomentAs(startOfWeek)) {
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
    fetchMyReports();
  }

  Future<void> fetchMyReports() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getMyReports();
      if (response.success && response.data != null) {
        state = state.copyWith(
          allReports: response.data!,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(ReportStatus? status) {
    if (status == null) {
      state = state.clearFilter();
    } else {
      state = state.copyWith(currentFilter: status);
    }
  }
}

final myReportsProvider = StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
  return MyReportsNotifier(reportService);
});
