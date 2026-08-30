import 'package:smartspace_admin/features/profile/models/user_model.dart';

import '../storage/secured_storage.dart';

const String _userKey = 'user';

class UserStorageService {
  Future<void> saveUser(UserModel user) async {
    await securedStorageService.set(_userKey, user);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final data = await securedStorageService.get<Map<String, dynamic>>(
      _userKey,
    );
    return data;
  }

  Future<void> removeUser() async {
    await securedStorageService.remove(_userKey);
  }

  Future<void> clear() async {
    await securedStorageService.clear();
  }
}

final userStorageService = UserStorageService();
