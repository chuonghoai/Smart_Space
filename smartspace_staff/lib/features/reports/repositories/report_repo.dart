import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getDangerousReports();
  Future<ApiResponse<List<ReportModel>>> getRecentReports();
}
