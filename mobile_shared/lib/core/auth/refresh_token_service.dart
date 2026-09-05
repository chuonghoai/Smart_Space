import 'package:mobile_shared/core/storage/secured_storage.dart';

const String _refreshTokenKey = 'refresh_token';

class RefreshTokenService {
  Future<void> saveRefreshToken(String token) async {
    await securedStorageService.set(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return await securedStorageService.get(_refreshTokenKey);
  }

  Future<void> removeRefreshToken() async {
    await securedStorageService.remove(_refreshTokenKey);
  }

  Future<void> clear() async {
    await securedStorageService.clear();
  }
}

final refreshTokenService = RefreshTokenService();
