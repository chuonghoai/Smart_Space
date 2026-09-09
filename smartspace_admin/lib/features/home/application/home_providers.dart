import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';

// Overview Provider
class AdminOverviewNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return _fetchOverview();
  }

  Future<Map<String, dynamic>?> _fetchOverview() async {
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

final adminOverviewProvider = AsyncNotifierProvider<AdminOverviewNotifier, Map<String, dynamic>?>(
  () => AdminOverviewNotifier(),
);

// Recent Activity Provider
class RecentActivityNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    return _fetchActivities();
  }

  Future<List<dynamic>> _fetchActivities() async {
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

final recentActivityProvider = AsyncNotifierProvider<RecentActivityNotifier, List<dynamic>>(
  () => RecentActivityNotifier(),
);

// Recent Reports Provider
class RecentReportNotifier extends FamilyAsyncNotifier<List<dynamic>, String> {
  @override
  Future<List<dynamic>> build(String arg) async {
    return _fetchReports(arg);
  }

  Future<List<dynamic>> _fetchReports(String tab) async {
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

final recentReportProvider = AsyncNotifierProviderFamily<RecentReportNotifier, List<dynamic>, String>(
  () => RecentReportNotifier(),
);
