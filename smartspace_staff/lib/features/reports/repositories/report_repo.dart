import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_date_range.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';

abstract class ReportRepo {
  /// Việc được giao cho staff. [severity] / [search] / [dateRange] null = không lọc chiều đó.
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({
    String status = 'all',
    ReportSeverity? severity,
    String? search,
    ReportDateRange? dateRange,
    StaffReportSort sort = StaffReportSort.latest,
    int page = 0,
    int limit = 10,
  });
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics();
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId);
  Future<ApiResponse<ReportDetailModel>> completeReport(
    String reportId, {
    required String note,
    required List<String> imageUrls,
  });
}
