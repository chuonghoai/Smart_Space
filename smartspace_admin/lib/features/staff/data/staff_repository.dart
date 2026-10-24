import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/features/staff/models/staff_trend_model.dart';

import '../models/staff_list_response.dart';

class StaffRepository {
  Future<ApiResponse<StaffListResponse>> getStaffs({
    int page = 1,
    int size = 10,
    String? search,
    String? status,
    String? positionId,
  }) async {
    return apiClient.get(
      '/admin/staffs',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'all') 'status': status,
        if (positionId != null && positionId != 'all') 'positionId': positionId,
      },
      decoder: (json) =>
          StaffListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse> updateStaffStatus(String staffId, String status) async {
    return apiClient.put(
      '/admin/staffs/$staffId/status',
      data: {'status': status},
    );
  }

  Future<ApiResponse> createStaff({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? positionId,
  }) async {
    return apiClient.post(
      '/admin/staffs',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (positionId != null) 'positionId': positionId,
      },
    );
  }

  /// [positionId]: null = giữ nguyên, '' = bỏ chức vụ, giá trị = đổi chức vụ.
  Future<ApiResponse> updateStaff({
    required String staffId,
    required String fullName,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? positionId,
  }) async {
    return apiClient.put(
      '/admin/staffs/$staffId',
      data: {
        'fullName': fullName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (positionId != null) 'positionId': positionId,
      },
    );
  }

  Future<StaffStatisticsModel> getStatistics() async {
    final response = await apiClient.get<StaffStatisticsModel>(
      '/admin/staffs/statistics',
      decoder: (json) =>
          StaffStatisticsModel.fromJson(json as Map<String, dynamic>),
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  /// period: 'daily' | 'weekly' | 'monthly'
  Future<List<StaffTrendItem>> getTrend(String period) async {
    final response = await apiClient.get<List<StaffTrendItem>>(
      '/admin/staffs/trend',
      queryParameters: {'period': period},
      decoder: (json) {
        final items = (json as Map<String, dynamic>)['items'] as List? ?? [];
        return items
            .map((e) => StaffTrendItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }
}

final staffRepository = StaffRepository();
