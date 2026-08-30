import 'package:smartspace_staff/core/api/api_response.dart';
import 'package:smartspace_staff/core/constants/use_mock.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo_api.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo_mock.dart';

class ReportService {
  final ReportRepo reportRepo;

  const ReportService({required this.reportRepo});

  Future<ApiResponse<List<ReportModel>>> getDangerousReports() async {
    return await reportRepo.getDangerousReports();
  }

  Future<ApiResponse<List<ReportModel>>> getRecentReports() async {
    return await reportRepo.getRecentReports();
  }
}

final reportService = ReportService(
  reportRepo: useMock ? ReportRepoMock() : ReportRepoApi(),
);
