import 'package:mobile_shared/core/api/api_response.dart';
import '../data/map_repository.dart';
import '../models/map_report_model.dart';

class MapService {
  final MapRepository _repository;

  MapService([MapRepository? repository])
      : _repository = repository ?? mapRepository;

  Future<ApiResponse<List<MapReportModel>>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) {
    return _repository.getMapReports(
      status: status,
      severity: severity,
      assigneeId: assigneeId,
      from: from,
      to: to,
      limit: limit,
    );
  }
}

final mapService = MapService();
