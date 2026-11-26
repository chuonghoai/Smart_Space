import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';

import '../models/sos_alert_page.dart';

class SosAdminRepository {
  static SosAlertModel _decode(dynamic json) => SosAlertModel.fromJson(json as Map<String, dynamic>);

  /// [status]: 'open' | 'resolved' | 'all'
  Future<ApiResponse<SosAlertPage>> list({required String status, int page = 1, int size = 50}) {
    return apiClient.get(
      '/admin/sos',
      queryParameters: {'status': status, 'page': page, 'size': size},
      decoder: (json) => SosAlertPage.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<int>> openCount() {
    return apiClient.get(
      '/admin/sos/open-count',
      decoder: (json) => ((json as Map<String, dynamic>)['count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ApiResponse<SosAlertModel>> detail(String id) {
    return apiClient.get('/admin/sos/$id', decoder: _decode);
  }

  Future<ApiResponse<SosAlertModel>> acknowledge(String id) {
    return apiClient.post('/admin/sos/$id/acknowledge', decoder: _decode);
  }

  Future<ApiResponse<SosAlertModel>> resolve(String id, {required bool falseAlarm, String? note}) {
    return apiClient.post(
      '/admin/sos/$id/resolve',
      data: {
        'false_alarm': falseAlarm,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      decoder: _decode,
    );
  }
}

final sosAdminRepository = SosAdminRepository();
