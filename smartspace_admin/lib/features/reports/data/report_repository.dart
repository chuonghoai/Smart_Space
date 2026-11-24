import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/auto_assign_models.dart';
import '../models/report_detail_model.dart';
import '../models/report_filter_model.dart';
import '../models/report_list_model.dart';
import '../models/report_statistics_model.dart';
import '../models/report_trend_model.dart';
import '../models/staff_model.dart';
import '../../home/models/recent_report_model.dart';

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
      queryParameters: {'size': 100, 'status': 'ACTIVE'},
      decoder: (json) {
        final map = json as Map<String, dynamic>;
        final staffsMap = map['staffs'] as Map<String, dynamic>?;
        List<dynamic> content = [];
        
        if (staffsMap != null) {
          final contentRaw = staffsMap['content'];
          if (contentRaw is List) {
            content = contentRaw;
          } else if (contentRaw is Map) {
            content = contentRaw.values.toList();
          }
        } else {
          if (map.containsKey('content')) {
            final contentRaw = map['content'];
            if (contentRaw is List) {
              content = contentRaw;
            } else if (contentRaw is Map) {
              content = contentRaw.values.toList();
            }
          }
        }
        
        return content
            .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<ReportDetailModel>> assignReport(
    String id, {
    required String staffId,
    required String severity,
    String source = 'MANUAL',
  }) async {
    return apiClient.post(
      '/admin/reports/$id/assign',
      data: {
        'staffId': staffId,
        'severity': severity,
        'source': source,
      },
      decoder: (json) => ReportDetailModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AutoAssignRecommendationModel>> getReportRecommendations(
    String id, {
    int limit = 3,
  }) async {
    return apiClient.get(
      '/admin/reports/$id/recommendations',
      queryParameters: {'limit': limit},
      decoder: (json) =>
          AutoAssignRecommendationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ReportDetailModel>> autoAssignReport(String id) async {
    return apiClient.post(
      '/admin/reports/$id/auto-assign',
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

  Future<ApiResponse<ReportTrendData>> getReportTrendData(String period) async {
    return apiClient.get(
      '/admin/reports/trend',
      queryParameters: {'period': period},
      decoder: (json) => ReportTrendData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// [excludeRehandling]: lọc "Đang xử lý"/"Đã xử lý" thì bỏ báo cáo xử lý lại,
  /// khớp với nhóm tách riêng trên thẻ thống kê. Kanban để `false` để báo cáo
  /// vẫn nằm trong cột trạng thái gốc.
  Future<ApiResponse<ReportListData>> getReportList(
    ReportFilter filter, {
    bool excludeRehandling = false,
  }) async {
    return apiClient.get(
      '/admin/reports',
      queryParameters: {
        ...filter.toQueryParams(),
        if (excludeRehandling) 'excludeRehandling': true,
      },
      decoder: (json) => ReportListData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateReportStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    return apiClient.patch(
      '/admin/reports/$id/status',
      data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      decoder: (json) => json as Map<String, dynamic>? ?? {},
    );
  }

  Future<ApiResponse<List<RecentReportModel>>> getUnsatisfactoryReports(String tab) async {
    return apiClient.get(
      '/admin/reports/unsatisfactory',
      queryParameters: {'tab': tab},
      decoder: (json) => (json as List<dynamic>)
          .map((e) => RecentReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<AutoAssignConfigModel>> getAutoAssignConfig() async {
    return apiClient.get(
      '/admin/auto-assign/config',
      decoder: (json) =>
          AutoAssignConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AutoAssignConfigModel>> updateAutoAssignConfig(
    AutoAssignConfigModel config,
  ) async {
    return apiClient.put(
      '/admin/auto-assign/config',
      data: config.toRequestJson(),
      decoder: (json) =>
          AutoAssignConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AutoAssignRecommendationModel>> simulateAutoAssign(
    AutoAssignSimulateRequestModel request,
  ) async {
    return apiClient.post(
      '/admin/auto-assign/simulate',
      data: request.toJson(),
      decoder: (json) =>
          AutoAssignRecommendationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AutoAssignAnalyticsModel>> getAutoAssignAnalytics() async {
    return apiClient.get(
      '/admin/auto-assign/analytics',
      decoder: (json) =>
          AutoAssignAnalyticsModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AssignmentDecisionLogPageModel>> getAutoAssignLogs({
    String? outcome,
    String? source,
    String? categoryId,
    int page = 1,
    int size = 15,
  }) async {
    return apiClient.get(
      '/admin/auto-assign/logs',
      queryParameters: {
        'page': page,
        'size': size,
        if (outcome != null && outcome.isNotEmpty && outcome != 'all')
          'outcome': outcome,
        if (source != null && source.isNotEmpty && source != 'all')
          'source': source,
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all')
          'categoryId': categoryId,
      },
      decoder: (json) =>
          AssignmentDecisionLogPageModel.fromJson(json as Map<String, dynamic>),
    );
  }
}

final reportRepository = ReportRepository();
