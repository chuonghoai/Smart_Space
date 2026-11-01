import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/delegation_rate_config_model.dart';

class DelegationRateConfigRepository {
  static const _path = '/admin/wallet/config/delegation';

  Future<ApiResponse<DelegationRateConfigModel>> getConfig() {
    return apiClient.get(
      _path,
      decoder: (json) => DelegationRateConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DelegationRateConfigModel>> updateRates({
    required double low,
    required double medium,
    required double high,
    required double critical,
  }) {
    return apiClient.put(
      _path,
      data: DelegationRateConfigModel.ratesToJson(low: low, medium: medium, high: high, critical: critical),
      decoder: (json) => DelegationRateConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }
}

final delegationRateConfigRepository = DelegationRateConfigRepository();
