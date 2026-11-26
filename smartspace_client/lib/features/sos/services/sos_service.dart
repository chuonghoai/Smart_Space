import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/repositories/sos_repo.dart';
import 'package:smartspace_client/features/sos/repositories/sos_repo_api.dart';
import 'package:smartspace_client/features/sos/repositories/sos_repo_mock.dart';

class SosService {
  final SosRepo repo;

  const SosService({required this.repo});

  Future<ApiResponse<SosAlertModel>> start({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) =>
      repo.start(latitude: latitude, longitude: longitude, accuracy: accuracy);

  Future<ApiResponse<SosAlertModel>> getActive() => repo.getActive();

  Future<ApiResponse<SosAlertModel>> updateLocation(
    String id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) =>
      repo.updateLocation(id, latitude: latitude, longitude: longitude, accuracy: accuracy);

  Future<ApiResponse<SosAlertModel>> markSafe(String id) => repo.markSafe(id);

  Future<ApiResponse<SosAlertModel>> getById(String id) => repo.getById(id);
}

final sosService = SosService(repo: useMock ? SosRepoMock() : SosRepoApi());
