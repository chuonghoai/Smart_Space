import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';

class ReportRepoMock implements ReportRepo {
  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({String status = 'all', int limit = 10}) async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: [],
    );
  }

  @override
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: ReportStatisticsModel(total: 0, byStatus: {}),
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId) async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: null,
    );
  }
}
