import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import '../data/map_repository.dart';
import '../models/admin_map_reports_result.dart';

class MapService {
  final MapRepository _repository;

  MapService([MapRepository? repository])
      : _repository = repository ?? mapRepository;

  Future<ApiResponse<AdminMapReportsResult>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    MapBounds? bounds,
    int limit = 500,
  }) {
    return _repository.getMapReports(
      status: status,
      severity: severity,
      assigneeId: assigneeId,
      from: from,
      to: to,
      bounds: bounds,
      limit: limit,
    );
  }
}

final mapService = MapService();
