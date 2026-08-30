import 'package:smartspace_client/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getDangerousReports();
  Future<ApiResponse<List<ReportModel>>> getRecentReports();
}
