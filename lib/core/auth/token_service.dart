import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _accessTokenKey = 'access_token';

class TokenService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> removeAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

final tokenService = TokenService();
