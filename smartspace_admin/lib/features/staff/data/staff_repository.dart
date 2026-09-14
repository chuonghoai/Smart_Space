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
}

final staffRepository = StaffRepository();
