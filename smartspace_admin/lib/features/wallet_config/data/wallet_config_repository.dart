import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/wallet_config_model.dart';

class WalletConfigRepository {
  Future<ApiResponse<WalletConfigModel>> getWalletConfig() async {
    return apiClient.get(
      '/admin/wallet/config',
      decoder: (json) => WalletConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<WalletConfigModel>> updateWalletConfig(WalletConfigModel config) async {
    return apiClient.put(
      '/admin/wallet/config',
      data: config.toJson(),
      decoder: (json) => WalletConfigModel.fromJson(json as Map<String, dynamic>),
    );
  }
}

final walletConfigRepository = WalletConfigRepository();

