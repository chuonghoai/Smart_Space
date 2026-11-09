import 'package:smartspace_client/features/reports/models/report_density_model.dart';
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

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getDangerousReports();
  Future<ApiResponse<List<ReportModel>>> getRecentReports();
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto);
  Future<ApiResponse<MyReportsPage>> getMyReports({
    String? status,
    EReportSeverity? severity,
    ReportDateRange? dateRange,
    String? search,
    int page = 1,
    int size = 20,
  });
  Future<ApiResponse<MyReportsSummary>> getMyReportsSummary();
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId);
  /// [sort] = [FeedSort.nearby] cần [lat]/[lng]; [lat]/[lng] cũng dùng để tính khoảng cách hiển thị.
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
  });
  Future<ApiResponse<MapReportsResult>> getReportsInBounds(
    MapBounds bounds, {
    MapReportFilter filter = MapReportFilter.all,
    String? timeframe,
    int limit = 300,
  });
  Future<ApiResponse<ReportDetailModel>> submitReview(
    String reportId, {
    required bool isResolved,
    int? rating,
    String? reason,
    List<String>? imageUrls,
  });
  Future<ApiResponse<NearbyReportsAlertResponse>> getNearbyAlerts({
    required double lat,
    required double lng,
    double radius = 200.0,
    bool notify = true,
  });
  Future<ApiResponse<ReportDetailModel>> updateReport(String reportId, ReportDto reportDto);
  Future<ApiResponse<ReportDetailModel>> cancelReport(String reportId);
  Future<ApiResponse<ReportDensityResult>> getReportDensity({
    required double north,
    required double south,
    required double east,
    required double west,
    double zoom = 14.0,
    String? timeframe,
  });
}