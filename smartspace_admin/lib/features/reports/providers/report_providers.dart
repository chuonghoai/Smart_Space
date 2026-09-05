import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/models/report_model.dart';
import 'package:smartspace_admin/features/reports/services/report_service.dart';
import 'package:mobile_shared/util/distance_updater_provider.dart';
import 'package:mobile_shared/util/location_service.dart';

class ReportsState {
  final List<ReportModel> dangerousReports;
  final List<ReportModel> recentReports;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchedDangerous;
  final DateTime? lastFetchedRecent;

  ReportsState({
    this.dangerousReports = const [],
    this.recentReports = const [],
    this.isLoading = false,
    this.error,
    this.lastFetchedDangerous,
    this.lastFetchedRecent,
  });

  ReportsState copyWith({
    List<ReportModel>? dangerousReports,
    List<ReportModel>? recentReports,
    bool? isLoading,
    String? error,
    DateTime? lastFetchedDangerous,
    DateTime? lastFetchedRecent,
  }) {
    return ReportsState(
      dangerousReports: dangerousReports ?? this.dangerousReports,
      recentReports: recentReports ?? this.recentReports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchedDangerous: lastFetchedDangerous ?? this.lastFetchedDangerous,
      lastFetchedRecent: lastFetchedRecent ?? this.lastFetchedRecent,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportService _service;
  final Ref _ref;

  ReportsNotifier(this._service, this._ref) : super(ReportsState()) {
    // Listen to distance updater to recalculate distances every minute
    _ref.listen<AsyncValue<DateTime>>(distanceUpdaterProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        _recalculateDistances();
      }
    });

    fetchDangerousReports();
    fetchRecentReports();
  }

  Future<void> _recalculateDistances() async {
    final position = await locationService.getCurrentPosition();
    if (position == null) return;
    
    debugPrint('=== DISTANCE AUDIT ===');
    debugPrint('User GPS: lat=${position.latitude}, lng=${position.longitude}');

    final updatedDangerous = state.dangerousReports.map((r) {
      final dist = locationService.calculateDistance(
        position.latitude,
        position.longitude,
        r.latitude,
        r.longitude,
      );
      return r.copyWith(distanceInMeters: dist);
    }).toList();

    final updatedRecent = state.recentReports.map((r) {
      final dist = locationService.calculateDistance(
        position.latitude,
        position.longitude,
        r.latitude,
        r.longitude,
      );
      return r.copyWith(distanceInMeters: dist);
    }).toList();

    debugPrint('======================');

    state = state.copyWith(
      dangerousReports: updatedDangerous,
      recentReports: updatedRecent,
    );
  }

  Future<void> fetchDangerousReports({bool forceRefresh = false}) async {
    if (!forceRefresh && state.lastFetchedDangerous != null) {
      final diff = DateTime.now().difference(state.lastFetchedDangerous!);
      if (diff.inMinutes < 10) return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getDangerousReports();
      if (response.success && response.data != null) {
        state = state.copyWith(
          dangerousReports: response.data!,
          isLoading: false,
          lastFetchedDangerous: DateTime.now(),
        );
        _recalculateDistances();
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRecentReports({bool forceRefresh = false}) async {
    if (!forceRefresh && state.lastFetchedRecent != null) {
      final diff = DateTime.now().difference(state.lastFetchedRecent!);
      if (diff.inMinutes < 10) return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getRecentReports();
      if (response.success && response.data != null) {
        state = state.copyWith(
          recentReports: response.data!,
          isLoading: false,
          lastFetchedRecent: DateTime.now(),
        );
        _recalculateDistances();
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDangerousReports(forceRefresh: true),
      fetchRecentReports(forceRefresh: true),
    ]);
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  return ReportsNotifier(reportService, ref);
});
