import 'package:smartspace_admin/core/api/api_client.dart';
import 'package:smartspace_admin/core/api/api_response.dart';
import 'package:smartspace_admin/features/reports/models/report_model.dart';
import 'package:smartspace_admin/features/reports/repositories/report_repo.dart';

class ReportRepoApi implements ReportRepo {
  @override
  Future<ApiResponse<List<ReportModel>>> getDangerousReports() async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/dangerous',
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
  Future<ApiResponse<List<ReportModel>>> getRecentReports() async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/recent',
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
}
