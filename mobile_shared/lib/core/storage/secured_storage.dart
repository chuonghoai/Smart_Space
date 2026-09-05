import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuredStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  
  Future<void> set(String key, dynamic value) async {
    final stringValue = jsonEncode(value);
    try {
      await _storage.write(key: key, value: stringValue);
    } catch (e) {
      // If keystore is corrupted, clearing it usually fixes the write issue
      await _storage.deleteAll();
      await _storage.write(key: key, value: stringValue);
    }
  }

  Future<T?> get<T>(String key) async {
    String? value;
    try {
      value = await _storage.read(key: key);
    } catch (e) {
      // Keystore is corrupted, clear old data
      await _storage.deleteAll();
      return null;
    }
    
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
