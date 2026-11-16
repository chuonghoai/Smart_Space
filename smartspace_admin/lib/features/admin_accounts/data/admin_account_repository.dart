import 'package:dio/dio.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/admin_account_list_response.dart';

class AdminAccountRepository {
  Future<ApiResponse<AdminAccountListResponse>> getAdmins({
    int page = 1,
    int size = 10,
    String? search,
    String? status,
  }) async {
    return apiClient.get(
      '/admin/admins',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'all') 'status': status,
      },
      decoder: (json) =>
          AdminAccountListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Backend gửi email thông tin đăng nhập (SMTP) đồng bộ trước khi trả kết quả,
  /// nên cần chờ lâu hơn mặc định — cùng lý do với tạo nhân viên.
  static const _createAdminTimeout = Duration(seconds: 30);

  Future<ApiResponse> createAdmin({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    return apiClient.post(
      '/admin/admins',
      options: Options(receiveTimeout: _createAdminTimeout),
      data: {
        'fullName': fullName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// [status]: 'active' | 'blocked'
  Future<ApiResponse> updateAdminStatus(String adminId, String status) async {
    return apiClient.put(
      '/admin/admins/$adminId/status',
      data: {'status': status},
    );
  }
}

final adminAccountRepository = AdminAccountRepository();
