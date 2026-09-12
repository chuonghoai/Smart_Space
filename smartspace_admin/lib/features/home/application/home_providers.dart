import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../models/admin_overview_model.dart';
import '../models/recent_activity_model.dart';
import '../models/recent_report_model.dart';

// Overview Provider
class AdminOverviewNotifier extends AsyncNotifier<AdminOverviewModel?> {
  @override
  Future<AdminOverviewModel?> build() async {
    return _fetchOverview();
  }

  Future<AdminOverviewModel?> _fetchOverview() async {
    final response = await homeRepository.getAdminOverview();
    if (response.success && response.data != null) {
      return response.data;
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchOverview());
  }
}

final adminOverviewProvider = AsyncNotifierProvider<AdminOverviewNotifier, AdminOverviewModel?>(
  () => AdminOverviewNotifier(),
);

// Recent Activity Provider
class RecentActivityNotifier extends AsyncNotifier<List<RecentActivityModel>> {
  @override
  Future<List<RecentActivityModel>> build() async {
    return _fetchActivities();
  }

  Future<List<RecentActivityModel>> _fetchActivities() async {
    final response = await homeRepository.getRecentActivities();
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchActivities());
  }
}

final recentActivityProvider = AsyncNotifierProvider<RecentActivityNotifier, List<RecentActivityModel>>(
  () => RecentActivityNotifier(),
);

// Recent Reports Provider
class RecentReportNotifier extends FamilyAsyncNotifier<List<RecentReportModel>, String> {
  @override
  Future<List<RecentReportModel>> build(String arg) async {
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 10), () {
      link.close();
    });
    ref.onDispose(() => timer.cancel());

    return _fetchReports(arg);
  }

  Future<List<RecentReportModel>> _fetchReports(String tab) async {
    final response = await homeRepository.getRecentReports(tab: tab);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchReports(arg));
  }
}

final recentReportProvider = AsyncNotifierProviderFamily<RecentReportNotifier, List<RecentReportModel>, String>(
  () => RecentReportNotifier(),
);


