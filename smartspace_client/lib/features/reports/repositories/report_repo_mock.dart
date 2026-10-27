import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
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

  @override
  Future<ApiResponse<MapReportsResult>> getReportsInBounds(MapBounds bounds, {int limit = 300}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    // Nhóm 4 report cùng toạ độ để kiểm tra luồng "không tách được → mở danh sách"
    final mockData = [
      for (var i = 0; i < 4; i++)
        ReportModel(
          id: 'map-same-$i',
          title: 'Ngập nước giao lộ #${i + 1}',
          description: 'Nước ngập sau mưa lớn',
          imageUrl: 'https://ui-avatars.com/api/?name=Flood&background=random',
          latitude: 10.8504,
          longitude: 106.7571,
          status: ReportStatus.pending,
          severity: i == 0 ? EReportSeverity.high : EReportSeverity.medium,
          createdAt: now.subtract(Duration(minutes: 15 * (i + 1))),
        ),
      for (var i = 0; i < 12; i++)
        ReportModel(
          id: 'map-spread-$i',
          title: 'Phản ánh khu vực trung tâm #${i + 1}',
          description: 'Dữ liệu mock cho bản đồ',
          imageUrl: 'https://ui-avatars.com/api/?name=R$i&background=random',
          latitude: 10.7700 + (i % 4) * 0.004,
          longitude: 106.6900 + (i ~/ 4) * 0.004,
          status: i.isEven ? ReportStatus.processing : ReportStatus.processed,
          severity: i % 5 == 0 ? EReportSeverity.critical : EReportSeverity.low,
          createdAt: now.subtract(Duration(hours: i + 1)),
        ),
    ];

    final inBounds = mockData
        .where((r) =>
            r.latitude >= bounds.minLat &&
            r.latitude <= bounds.maxLat &&
            r.longitude >= bounds.minLng &&
            r.longitude <= bounds.maxLng)
        .toList();

    return ApiResponse(
      success: true,
      message: 'Success',
      data: MapReportsResult(
        reports: inBounds.take(limit).toList(),
        truncated: inBounds.length > limit,
      ),
    );
  }

  @override
  Future<ApiResponse<List<ReportModel>>> getMyReports({String? status, int limit = 50}) async {
    await Future.delayed(const Duration(seconds: 1));
    List<ReportModel> mockData = [
      ReportModel(
        id: 'm1',
        title: 'Đèn đường hỏng',
        description: 'Đèn không sáng',
        imageUrl: 'https://ui-avatars.com/api/?name=Light&background=random',
        latitude: 10.8231,
        longitude: 106.6297,
        status: ReportStatus.processing,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReportModel(
        id: 'm2',
        title: 'Hố ga mất nắp',
        description: 'Nguy hiểm',
        imageUrl: 'https://ui-avatars.com/api/?name=Hole&background=random',
        latitude: 10.8231,
        longitude: 106.6297,
        status: ReportStatus.processed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReportModel(
        id: 'm3',
        title: 'Rác thải sai quy định',
        description: 'Rác đổ bừa bãi',
        imageUrl: 'https://ui-avatars.com/api/?name=Trash&background=random',
        latitude: 10.8231,
        longitude: 106.6297,
        status: ReportStatus.rejected,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    if (status != null) {
      mockData = mockData.where((r) => r.status.name == status).toList();
    }

    return ApiResponse(
      success: true,
      message: 'Success',
      data: mockData.take(limit).toList(),
    );
  }

  @override
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto) async {
    await Future.delayed(const Duration(seconds: 2));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: ReportModel(
        id: 'new_1',
        title: reportDto.title,
        description: reportDto.description,
        imageUrl: reportDto.imageUrls.isNotEmpty ? reportDto.imageUrls.first : '',
        latitude: reportDto.latitude,
        longitude: reportDto.longitude,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId) async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: ReportDetailModel(
        id: reportId,
        title: 'Mock Report Title',
        description: 'Mock Report Description',
        imageUrls: ['https://ui-avatars.com/api/?name=Mock&background=random'],
        latitude: 10.8231,
        longitude: 106.6297,
        status: ReportStatus.pending,
        severity: EReportSeverity.high,
        isAnonymous: false,
        address: 'Mock Address',
        locationDescription: 'Mock Location',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiResponse<ReportFeedPage>> getFeed({String? status, int page = 1, int size = 10, double? lat, double? lng}) async {
    final detail = (await getReportDetail('f$page')).data!;
    return ApiResponse(
      success: true,
      message: 'Success',
      data: ReportFeedPage(
        items: [ReportFeedItem(report: detail, reporterName: 'Mock User')],
        totalPages: 1,
      ),
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> submitReview(
    String reportId, {
    required bool isResolved,
    int? rating,
    String? reason,
    List<String>? imageUrls,
  }) async {
    final detail = (await getReportDetail(reportId)).data!;
    return ApiResponse(
      success: true,
      message: 'Success',
      data: detail.copyWith(
        isReviewResolved: isResolved,
        rating: rating,
        reviewNote: reason,
        reviewImageUrls: imageUrls,
        reviewedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiResponse<NearbyReportsAlertResponse>> getNearbyAlerts({
    required double lat,
    required double lng,
    double radius = 200.0,
    bool notify = true,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Success',
      data: NearbyReportsAlertResponse(count: 0, reports: []),
    );
  }
}
