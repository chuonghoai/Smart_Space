import 'package:intl/intl.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/map_report_model.dart';

class MapRepository {
  Future<ApiResponse<List<MapReportModel>>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
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
        'limit': limit,
      },
      decoder: (json) => (json as List<dynamic>)
          .map((e) => MapReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final mapRepository = MapRepository();
