import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

class HomeRepository {
  Future<ApiResponse<Map<String, dynamic>>> getAdminOverview() async {
    return apiClient.get('/admin/home/overview');
  }

  Future<ApiResponse<List<dynamic>>> getRecentActivities({int limit = 6}) async {
    return apiClient.get(
      '/admin/activities',
      queryParameters: {'limit': limit},
    );
  }

  Future<ApiResponse<List<dynamic>>> getRecentReports({
    String tab = 'all',
    int limit = 6,
  }) async {
    return apiClient.get(
      '/admin/reports/recent',
      queryParameters: {
        'tab': tab,
        'limit': limit,
      },
    );
  }
}

final homeRepository = HomeRepository();
