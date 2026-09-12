import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/admin_overview_model.dart';
import '../models/recent_activity_model.dart';
import '../models/recent_report_model.dart';

class HomeRepository {
  Future<ApiResponse<AdminOverviewModel>> getAdminOverview() async {
    return apiClient.get(
      '/admin/home/overview',
      decoder: (json) => AdminOverviewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<RecentActivityModel>>> getRecentActivities({int limit = 6}) async {
    return apiClient.get(
      '/admin/activities',
      queryParameters: {'limit': limit},
      decoder: (json) => (json as List<dynamic>)
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<RecentReportModel>>> getRecentReports({
    String tab = 'all',
    int limit = 6,
  }) async {
    return apiClient.get(
      '/admin/reports/recent',
      queryParameters: {
        'tab': tab,
        'limit': limit,
      },
      decoder: (json) => (json as List<dynamic>)
          .map((e) => RecentReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final homeRepository = HomeRepository();

