import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';

class ReportRepoApi implements ReportRepo {

  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({String status = 'all', int page = 0, int limit = 10}) async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/staff/assigned?status=$status&page=$page&limit=$limit',
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics() async {
    return await apiClient.get<ReportStatisticsModel>(
      '/reports/staff/statistics',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportStatisticsModel.fromJson(json);
        }
        return ReportStatisticsModel(total: 0, byStatus: {});
      },
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId) async {
    return await apiClient.get<ReportDetailModel>(
      '/reports/$reportId',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }
}
