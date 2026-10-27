import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/auth/models/user_model.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return await userStorageService.getUser();
});
