import 'package:flutter/material.dart';
import 'package:smartspace_staff/core/auth/user_storage_service.dart';
import 'package:smartspace_staff/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/features/profile/models/user_model.dart';
import 'package:smartspace_staff/routes/app_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class SettingsController extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadUser() async {
    _user = await userStorageService.getUser();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.logout();
      appRouter.go(RouterPath.login);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
