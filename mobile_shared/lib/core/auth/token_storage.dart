import 'package:mobile_shared/core/storage/secured_storage.dart';
import 'package:flutter/foundation.dart';
import 'app_scope.dart';

class TokenStorage {
  static AppScope _scope = AppScope.unknown;

  static Future<void> init(AppScope scope) async {
    _scope = scope;
    
    // Clean up legacy tokens if they exist to prevent unintended cross-app pollution
    final legacyAccessToken = await securedStorageService.get('access_token');
    if (legacyAccessToken != null) {
      debugPrint('[TokenStorage] Found legacy access_token, removing it to enforce isolation');
      await securedStorageService.remove('access_token');
    }
    
    final legacyRefreshToken = await securedStorageService.get('refresh_token');
    if (legacyRefreshToken != null) {
      debugPrint('[TokenStorage] Found legacy refresh_token, removing it to enforce isolation');
      await securedStorageService.remove('refresh_token');
    }
  }

  static AppScope get scope => _scope;

  static String get _accessTokenKey {
    if (_scope == AppScope.unknown) throw Exception("TokenStorage scope not initialized. Call TokenStorage.init() in main.");
    return '${_scope.name}.access_token';
  }

  static String get _refreshTokenKey {
    if (_scope == AppScope.unknown) throw Exception("TokenStorage scope not initialized. Call TokenStorage.init() in main.");
    return '${_scope.name}.refresh_token';
  }

  static Future<void> saveAccessToken(String token) async {
    await securedStorageService.set(_accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    return await securedStorageService.get(_accessTokenKey);
  }

  static Future<void> removeAccessToken() async {
    await securedStorageService.remove(_accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await securedStorageService.set(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return await securedStorageService.get(_refreshTokenKey);
  }

  static Future<void> removeRefreshToken() async {
    await securedStorageService.remove(_refreshTokenKey);
  }

  static Future<void> clearAuth() async {
    await removeAccessToken();
    await removeRefreshToken();
  }
}
