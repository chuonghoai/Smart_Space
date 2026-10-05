import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({String status = 'all', int page = 0, int limit = 10});
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics();
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId);
}
