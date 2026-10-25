import 'package:intl/intl.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import '../models/admin_map_reports_result.dart';

class MapRepository {
  Future<ApiResponse<AdminMapReportsResult>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
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
}

final mapRepository = MapRepository();
