import 'package:intl/intl.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import '../models/admin_map_reports_result.dart';
import '../models/report_density_model.dart';

class MapRepository {
  Future<ApiResponse<AdminMapReportsResult>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    String? timeframe,
    MapBounds? bounds,
    int limit = 500,
  }) async {
    final fmt = DateFormat('yyyy-MM-dd');
    return apiClient.get(
      '/admin/reports/map',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        if (assigneeId != null && assigneeId.isNotEmpty) 'assigneeId': assigneeId,
        if (from != null) 'from': fmt.format(from),
        if (to != null) 'to': fmt.format(to),
        if (timeframe != null && timeframe.isNotEmpty) 'timeframe': timeframe,
        // Endpoint admin dùng camelCase cho mọi param
        if (bounds != null) ...{
          'minLat': bounds.minLat,
          'maxLat': bounds.maxLat,
          'minLng': bounds.minLng,
          'maxLng': bounds.maxLng,
        },
        'limit': limit,
      },
      decoder: (json) => json is Map<String, dynamic>
          ? AdminMapReportsResult.fromJson(json)
          : AdminMapReportsResult.empty,
    );
  }

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
    return apiClient.get(
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

final mapRepository = MapRepository();
