import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getDangerousReports();
  Future<ApiResponse<List<ReportModel>>> getRecentReports();
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto);
}
