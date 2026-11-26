import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';

abstract class SosRepo {
  Future<ApiResponse<SosAlertModel>> start({
    required double latitude,
    required double longitude,
    double? accuracy,
  });

  /// data == null khi không có SOS đang mở.
  Future<ApiResponse<SosAlertModel>> getActive();

  Future<ApiResponse<SosAlertModel>> updateLocation(
    String id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  });

  Future<ApiResponse<SosAlertModel>> markSafe(String id);

  /// Xem SOS của chính mình hoặc của người mình bảo hộ.
  Future<ApiResponse<SosAlertModel>> getById(String id);
}
