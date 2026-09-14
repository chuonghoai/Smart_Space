import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/staff_list_response.dart';

class StaffRepository {
  Future<ApiResponse<StaffListResponse>> getStaffs({
    int page = 1,
    int size = 10,
    String? search,
    String? status,
  }) async {
    return apiClient.get(
      '/admin/staffs',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'all') 'status': status,
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
      },
    );
  }
  Future<ApiResponse> updateStaff({
    required String staffId,
    required String fullName,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
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
      },
    );
  }
}

final staffRepository = StaffRepository();
