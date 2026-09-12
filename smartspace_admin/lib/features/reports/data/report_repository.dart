import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/report_detail_model.dart';
import '../models/staff_model.dart';

class ReportRepository {
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String id) async {
    return apiClient.get(
      '/reports/$id',
      decoder: (json) => ReportDetailModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<StaffModel>>> getStaffs() async {
    return apiClient.get(
      '/admin/staffs',
      decoder: (json) => (json as List<dynamic>)
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<ReportDetailModel>> assignReport(
    String id, {
    required String staffId,
    required String severity,
  }) async {
    return apiClient.post(
      '/admin/reports/$id/assign',
      data: {
        'staffId': staffId,
        'severity': severity,
      },
      decoder: (json) => ReportDetailModel.fromJson(json as Map<String, dynamic>),
    );
  }
}

final reportRepository = ReportRepository();
