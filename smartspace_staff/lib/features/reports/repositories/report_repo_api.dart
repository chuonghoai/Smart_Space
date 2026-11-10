import 'package:dio/dio.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_date_range.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/report_detail_model.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';

class ReportRepoApi implements ReportRepo {

  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({
    String status = 'all',
    ReportSeverity? severity,
    String? search,
    ReportDateRange? dateRange,
    StaffReportSort sort = StaffReportSort.latest,
    int page = 0,
    int limit = 10,
  }) async {
    final keyword = search?.trim();
    return await apiClient.get<List<ReportModel>>(
      '/reports/staff/assigned',
      queryParameters: {
        'status': status,
        if (severity != null && severity != ReportSeverity.unknown) 'severity': severity.name,
        if (keyword != null && keyword.isNotEmpty) 'search': keyword,
        if (dateRange != null) 'from': dateRange.fromQuery,
        if (dateRange != null) 'to': dateRange.toQuery,
        'sort': sort.name,
        'page': page,
        'limit': limit,
      },
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics() async {
    return await apiClient.get<ReportStatisticsModel>(
      '/reports/staff/statistics',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportStatisticsModel.fromJson(json);
        }
        return ReportStatisticsModel(total: 0, byStatus: {});
      },
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId) async {
    return await apiClient.get<ReportDetailModel>(
      '/reports/$reportId',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> completeReport(
    String reportId, {
    required String note,
    required List<String> imageUrls,
  }) async {
    return await apiClient.post<ReportDetailModel>(
      '/reports/$reportId/complete',
      data: {
        'note': note,
        'image_urls': imageUrls,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }
}
