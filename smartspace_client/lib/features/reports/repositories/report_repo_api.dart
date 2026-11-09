import 'package:smartspace_client/features/reports/models/report_density_model.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/feed_sort.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/my_reports_page_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';

class ReportRepoApi implements ReportRepo {
  @override
  Future<ApiResponse<List<ReportModel>>> getDangerousReports() async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/dangerous',
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
  Future<ApiResponse<List<ReportModel>>> getRecentReports() async {
    return await apiClient.get<List<ReportModel>>(
      '/reports/recent',
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
  Future<ApiResponse<MapReportsResult>> getReportsInBounds(
    MapBounds bounds, {
    MapReportFilter filter = MapReportFilter.all,
    String? timeframe,
    int limit = 300,
  }) async {
    final Map<String, dynamic> params = {
      ...bounds.toQueryParameters(),
      'filter': filter.name,
      'limit': limit,
    };
    if (timeframe != null && timeframe.isNotEmpty) {
      params['timeframe'] = timeframe;
    }
    return await apiClient.get<MapReportsResult>(
      '/reports/map',
      queryParameters: params,
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return MapReportsResult.fromJson(json);
        }
        return const MapReportsResult(reports: [], truncated: false);
      },
    );
  }

  @override
  Future<ApiResponse<MyReportsPage>> getMyReports({
    String? status,
    EReportSeverity? severity,
    ReportDateRange? dateRange,
    String? search,
    int page = 1,
    int size = 20,
  }) async {
    final keyword = search?.trim();
    return await apiClient.get<MyReportsPage>(
      '/reports/my-reports',
      queryParameters: {
        'page': page,
        'size': size,
        'status': ?status,
        'severity': ?severity?.name,
        'from': ?dateRange?.fromQuery,
        'to': ?dateRange?.toQuery,
        if (keyword != null && keyword.isNotEmpty) 'search': keyword,
      },
      decoder: (json) {
        if (json is Map<String, dynamic>) return MyReportsPage.fromJson(json);
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ApiResponse<MyReportsSummary>> getMyReportsSummary() async {
    return await apiClient.get<MyReportsSummary>(
      '/reports/my-reports/summary',
      decoder: (json) {
        if (json is Map<String, dynamic>) return MyReportsSummary.fromJson(json);
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto) async {
    return await apiClient.post<ReportModel>(
      '/reports',
      data: reportDto.toJson(),
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportModel.fromJson(json);
        }
        throw Exception('Invalid response format');
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
  Future<ApiResponse<ReportFeedPage>> getFeed({
    String? status,
    EReportSeverity? severity,
    ReportDateRange? dateRange,
    String? search,
    FeedSort sort = FeedSort.latest,
    int page = 1,
    int size = 10,
    double? lat,
    double? lng,
  }) async {
    final keyword = search?.trim();
    return await apiClient.get<ReportFeedPage>(
      '/reports/feed',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': sort.name,
        'status': ?status,
        'severity': ?severity?.name,
        'from': ?dateRange?.fromQuery,
        'to': ?dateRange?.toQuery,
        if (keyword != null && keyword.isNotEmpty) 'search': keyword,
        if (lat != null && lng != null) 'user_lat': lat,
        if (lat != null && lng != null) 'user_long': lng,
      },
      decoder: (json) {
        if (json is Map<String, dynamic>) return ReportFeedPage.fromJson(json);
        throw Exception('Invalid response format');
      },
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
    return await apiClient.post<ReportDetailModel>(
      '/reports/$reportId/review',
      data: {
        'is_resolved': isResolved,
        'rating': ?rating,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (imageUrls != null && imageUrls.isNotEmpty) 'image_urls': imageUrls,
      },
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ApiResponse<NearbyReportsAlertResponse>> getNearbyAlerts({
    required double lat,
    required double lng,
    double radius = 200.0,
    bool notify = true,
  }) async {
    return await apiClient.get<NearbyReportsAlertResponse>(
      '/reports/nearby-alerts',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'notify': notify,
      },
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return NearbyReportsAlertResponse.fromJson(json);
        }
        return NearbyReportsAlertResponse(count: 0, reports: []);
      },
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> updateReport(String reportId, ReportDto reportDto) async {
    return await apiClient.put<ReportDetailModel>(
      '/reports/$reportId',
      data: reportDto.toJson(),
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }

  @override
  Future<ApiResponse<ReportDetailModel>> cancelReport(String reportId) async {
    return await apiClient.post<ReportDetailModel>(
      '/reports/$reportId/cancel',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDetailModel.fromJson(json);
        }
        throw Exception('Invalid response format');
      },
    );
  }
  @override
  Future<ApiResponse<ReportDensityResult>> getReportDensity({
    required double north,
    required double south,
    required double east,
    required double west,
    double zoom = 14.0,
    String? timeframe,
  }) async {
    final Map<String, dynamic> params = {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
      'zoom': zoom,
    };
    if (timeframe != null && timeframe.isNotEmpty) {
      params['timeframe'] = timeframe;
    }
    return await apiClient.get<ReportDensityResult>(
      '/reports/density',
      queryParameters: params,
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return ReportDensityResult.fromJson(json);
        }
        throw Exception('Invalid density response format');
      },
    );
  }
}