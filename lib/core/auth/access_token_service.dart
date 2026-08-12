import 'package:smartspace_admin/core/storage/secured_storage.dart';

const String _accessTokenKey = 'access_token';

class AccessTokenService {
  Future<void> saveAccessToken(String token) async {
    await securedStorageService.set(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return await securedStorageService.get(_accessTokenKey);
  }

  Future<void> removeAccessToken() async {
    await securedStorageService.remove(_accessTokenKey);
  }

  Future<void> clear() async {
    await securedStorageService.clear();
  }
}

final accessTokenService = AccessTokenService();
