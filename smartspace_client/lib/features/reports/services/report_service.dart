import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo_api.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo_mock.dart';

class ReportService {
  final ReportRepo reportRepo;

  const ReportService({required this.reportRepo});

  Future<ApiResponse<List<ReportModel>>> getDangerousReports() async {
    return await reportRepo.getDangerousReports();
  }

  Future<ApiResponse<List<ReportModel>>> getRecentReports() async {
    return await reportRepo.getRecentReports();
  }

  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto) async {
    return await reportRepo.createReport(reportDto);
  }
}

final reportService = ReportService(
  reportRepo: useMock ? ReportRepoMock() : ReportRepoApi(),
);
