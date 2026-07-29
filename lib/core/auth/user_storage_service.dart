import '../local_storage/local_storage_service.dart';

const String _userKey = 'user';

class UserStorageService {
  Future<void> saveUser(Map<String, dynamic> user) async {
    await localStorageService.set(_userKey, user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final data = await localStorageService.get<Map<String, dynamic>>(_userKey);
    return data;
  }

  Future<void> removeUser() async {
    await localStorageService.remove(_userKey);
  }

  Future<void> clear() async {
    await localStorageService.clear();
  }
}

final userStorageService = UserStorageService();
