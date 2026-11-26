import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/repositories/sos_repo.dart';

class SosRepoApi implements SosRepo {
  static SosAlertModel _decode(dynamic json) =>
      SosAlertModel.fromJson(json as Map<String, dynamic>);

  static Map<String, dynamic> _location(double latitude, double longitude, double? accuracy) => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': ?accuracy,
      };

  @override
  Future<ApiResponse<SosAlertModel>> start({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    return apiClient.post<SosAlertModel>(
      '/sos',
      data: _location(latitude, longitude, accuracy),
      decoder: _decode,
    );
  }

  @override
  Future<ApiResponse<SosAlertModel>> getActive() {
    return apiClient.get<SosAlertModel>('/sos/active', decoder: _decode);
  }

  @override
  Future<ApiResponse<SosAlertModel>> updateLocation(
    String id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    return apiClient.patch<SosAlertModel>(
      '/sos/$id/location',
      data: _location(latitude, longitude, accuracy),
      decoder: _decode,
    );
  }

  @override
  Future<ApiResponse<SosAlertModel>> markSafe(String id) {
    return apiClient.post<SosAlertModel>('/sos/$id/safe', decoder: _decode);
  }

  @override
  Future<ApiResponse<SosAlertModel>> getById(String id) {
    return apiClient.get<SosAlertModel>('/sos/$id', decoder: _decode);
  }
}
