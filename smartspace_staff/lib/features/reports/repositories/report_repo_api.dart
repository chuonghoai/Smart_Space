import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';

class ReportRepoApi implements ReportRepo {

  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({String status = 'all', int limit = 10}) async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/staff/assigned?status=$status&limit=$limit',
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
}
