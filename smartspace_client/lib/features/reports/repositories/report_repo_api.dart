import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';

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

  @override
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto) async {
    return await apiClient.post<ReportModel>(
      '/reports',
      data: reportDto.toJson(),
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }
}
