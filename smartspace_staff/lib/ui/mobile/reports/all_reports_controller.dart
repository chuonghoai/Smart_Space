import 'package:flutter/material.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';

class AllReportsState {
  final List<ReportModel> reports;
  final bool isLoading;
  final bool hasMore;
  final String filter;
  final int page;
  final String? error;
  final ReportStatisticsModel? stats;

  const AllReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.filter = 'all',
    this.page = 0,
    this.error,
    this.stats,
  });

  AllReportsState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? hasMore,
    String? filter,
    int? page,
    String? error,
    ReportStatisticsModel? stats,
  }) {
    return AllReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class AllReportsController extends ChangeNotifier {
  final ReportService _reportService;
  AllReportsState _state;

  AllReportsController({
    ReportService? service,
    String initialFilter = 'all',
  })  : _reportService = service ?? reportService,
        _state = AllReportsState(filter: initialFilter) {
    fetchInitial();
  }

  AllReportsState get state => _state;

  Future<void> fetchInitial() async {
    _state = _state.copyWith(isLoading: true, error: null, page: 0, reports: [], hasMore: true);
    notifyListeners();

    try {
      final responses = await Future.wait([
        _reportService.getStaffAssignedReports(
          status: _state.filter,
          page: 0,
          limit: 20,
        ),
        _reportService.getStaffStatistics(),
      ]);

      final response = responses[0] as ApiResponse<List<ReportModel>>;
      final statsResponse = responses[1] as ApiResponse<ReportStatisticsModel>;

      if (response.success && response.data != null) {
        final newReports = response.data!;
        _state = _state.copyWith(
          reports: newReports,
          isLoading: false,
          hasMore: newReports.length == 20,
          page: 1,
          stats: statsResponse.success ? statsResponse.data : _state.stats,
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.isLoading || !_state.hasMore) return;

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final response = await _reportService.getStaffAssignedReports(
        status: _state.filter,
        page: _state.page,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final newReports = response.data!;
        _state = _state.copyWith(
          reports: [..._state.reports, ...newReports],
          isLoading: false,
          hasMore: newReports.length == 20,
          page: _state.page + 1,
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  void setFilter(String newFilter) {
    if (_state.filter == newFilter) return;
    _state = _state.copyWith(filter: newFilter);
    fetchInitial();
  }
}
