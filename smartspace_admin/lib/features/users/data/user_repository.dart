import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/user_detail_model.dart';
import '../models/user_page_model.dart';
import '../models/user_statistics_model.dart';
import '../models/user_trend_model.dart';

class UserRepository {
  Future<ApiResponse<UserPageModel>> getUsers({
    int page = 1,
    int size = 10,
    String? search,
    String sort = 'newest',
  }) async {
    return apiClient.get(
      '/admin/users',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': sort,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      decoder: (json) => UserPageModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<UserStatisticsModel> getStatistics() async {
    final response = await apiClient.get<UserStatisticsModel>(
      '/admin/users/statistics',
      decoder: (json) =>
          UserStatisticsModel.fromJson(json as Map<String, dynamic>),
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<List<UserTrendItem>> getRegistrationTrend(String period) async {
    final response = await apiClient.get<List<UserTrendItem>>(
      '/admin/users/trend',
      queryParameters: {'period': period},
      decoder: (json) {
        final items = (json as Map<String, dynamic>)['items'] as List? ?? [];
        return items
            .map((e) => UserTrendItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<UserDetailModel> getUserDetail(String userId) async {
    final response = await apiClient.get<UserDetailModel>(
      '/admin/users/$userId',
      decoder: (json) => UserDetailModel.fromJson(json as Map<String, dynamic>),
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }
}

final userRepository = UserRepository();
