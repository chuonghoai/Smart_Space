import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import '../data/map_repository.dart';
import '../models/admin_map_reports_result.dart';
import '../models/report_density_model.dart';

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
    String? timeframe,
    MapBounds? bounds,
    int limit = 500,
  }) {
    return _repository.getMapReports(
      status: status,
      severity: severity,
      assigneeId: assigneeId,
      from: from,
      to: to,
      timeframe: timeframe,
      bounds: bounds,
      limit: limit,
    );
  }

  Future<ApiResponse<ReportDensityResult>> getReportDensity({
    required double north,
    required double south,
    required double east,
    required double west,
    double zoom = 14.0,
    String? timeframe,
  }) {
    return _repository.getReportDensity(
      north: north,
      south: south,
      east: east,
      west: west,
      zoom: zoom,
      timeframe: timeframe,
    );
  }
}

final mapService = MapService();
