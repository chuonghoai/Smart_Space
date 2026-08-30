import 'package:smartspace_client/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';

class ReportRepoMock implements ReportRepo {
  @override
  Future<ApiResponse<List<ReportModel>>> getDangerousReports() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: [
        ReportModel(
          id: 'd1',
          title: 'Sạt lở đất đá nghiêm trọng',
          description: 'Sạt lở ở quốc lộ 1A',
          imageUrl: 'https://ui-avatars.com/api/?name=Danger&background=random',
          latitude: 10.882214, // near HCMC
          longitude: 106.764678,
          status: ReportStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ReportModel(
          id: 'd2',
          title: 'Sạt lở đất đá nghiêm trọng',
          description: 'Sạt lở ở quốc lộ 1A',
          imageUrl: 'https://ui-avatars.com/api/?name=Danger&background=random',
          latitude: 10.8231, // near HCMC
          longitude: 106.6297,
          status: ReportStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ReportModel(
          id: 'd3',
          title: 'Sạt lở đất đá nghiêm trọng',
          description: 'Sạt lở ở quốc lộ 1A',
          imageUrl: 'https://ui-avatars.com/api/?name=Danger&background=random',
          latitude: 10.8231, // near HCMC
          longitude: 106.6297,
          status: ReportStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<List<ReportModel>>> getRecentReports() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: [
        ReportModel(
          id: 'r1',
          title: 'Cây đổ ngang đường',
          description: 'Gió to làm cây ngã',
          imageUrl: 'https://ui-avatars.com/api/?name=Tree&background=random',
          latitude: 10.882214, // near HCMC
          longitude: 106.764678,
          status: ReportStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        ReportModel(
          id: 'r2',
          title: 'Ngập lụt đoạn đường Võ Văn Ngân',
          description: 'Nước ngập sâu 50cm',
          imageUrl: 'https://ui-avatars.com/api/?name=Flood&background=random',
          latitude: 10.8504, // Thu Duc
          longitude: 106.7571,
          status: ReportStatus.processing,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
    );
  }
}
