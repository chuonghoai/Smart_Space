import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/report_detail_model.dart';
import '../models/report_filter_model.dart';
import '../models/report_list_model.dart';
import '../models/report_statistics_model.dart';
import '../models/report_trend_model.dart';
import '../models/staff_model.dart';

class ReportRepository {
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String id) async {
    return apiClient.get(
      '/reports/$id',
      decoder: (json) => ReportDetailModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<StaffModel>>> getStaffs() async {
    return apiClient.get(
      '/admin/staffs',
      decoder: (json) => (json as List<dynamic>)
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<ReportDetailModel>> assignReport(
    String id, {
    required String staffId,
    required String severity,
  }) async {
    return apiClient.post(
      '/admin/reports/$id/assign',
      data: {
        'staffId': staffId,
        'severity': severity,
      },
      decoder: (json) => ReportDetailModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ReportStatisticsModel>> getReportStatistics() async {
    return apiClient.get(
      '/admin/reports/statistics',
      decoder: (json) => ReportStatisticsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<ReportTrendItem>>> getReportTrend(String period) async {
    return apiClient.get(
      '/admin/reports/trend',
      queryParameters: {'period': period},
      decoder: (json) {
        final map = json as Map<String, dynamic>;
        final list = map['items'] as List<dynamic>? ?? [];
        return list
            .map((e) => ReportTrendItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<ReportListData>> getReportList(ReportFilter filter) async {
    return apiClient.get(
      '/admin/reports',
      queryParameters: filter.toQueryParams(),
      decoder: (json) => ReportListData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateReportStatus(
      String id, String status) async {
    return apiClient.patch(
      '/admin/reports/$id/status',
      data: {'status': status},
      decoder: (json) => json as Map<String, dynamic>? ?? {},
    );
  }
}

final reportRepository = ReportRepository();
