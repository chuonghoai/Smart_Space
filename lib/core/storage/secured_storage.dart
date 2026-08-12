import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuredStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> set(String key, dynamic value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<T?> get<T>(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) {
      return null;
    }
    return jsonDecode(value) as T;
  }

  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

final securedStorageService = SecuredStorageService();
