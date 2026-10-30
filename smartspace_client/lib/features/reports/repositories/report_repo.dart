import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/models/report_dto.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';

import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';

abstract class ReportRepo {
  Future<ApiResponse<List<ReportModel>>> getDangerousReports();
  Future<ApiResponse<List<ReportModel>>> getRecentReports();
  Future<ApiResponse<ReportModel>> createReport(ReportDto reportDto);
  Future<ApiResponse<List<ReportModel>>> getMyReports({String? status, int limit = 50});
  Future<ApiResponse<ReportDetailModel>> getReportDetail(String reportId);
  Future<ApiResponse<ReportFeedPage>> getFeed({String? status, int page = 1, int size = 10, double? lat, double? lng});
  Future<ApiResponse<MapReportsResult>> getReportsInBounds(
    MapBounds bounds, {
    MapReportFilter filter = MapReportFilter.all,
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
}

