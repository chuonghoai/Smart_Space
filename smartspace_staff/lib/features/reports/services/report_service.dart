import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo_api.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo_mock.dart';

class ReportService {
  final ReportRepo reportRepo;

  const ReportService({required this.reportRepo});

  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({String status = 'all', int page = 0, int limit = 10}) async {
    return await reportRepo.getStaffAssignedReports(status: status, page: page, limit: limit);
  }

  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics() async {
    return await reportRepo.getStaffStatistics();
  }

  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId) async {
    return await reportRepo.getReportDetail(reportId);
  }
}

final reportService = ReportService(
  reportRepo: useMock ? ReportRepoMock() : ReportRepoApi(),
);
