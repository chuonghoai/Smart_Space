import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/core/auth/access_token_service.dart';
import 'package:smartspace_admin/core/auth/refresh_token_service.dart';
import 'package:smartspace_admin/core/auth/user_storage_service.dart';
import 'package:smartspace_admin/core/interceptors/error_interceptor.dart';
import 'package:smartspace_admin/core/localization/locale_provider.dart';
import 'package:smartspace_admin/core/theme/theme_provider.dart';

class SplashController extends ChangeNotifier {
  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load theme and locale
      await Future.wait([
        themeProvider.initialize(),
        localeProvider.initialize(),
      ]);

      // Check authentication
      final accessToken = await accessTokenService.getAccessToken();
      final refreshToken = await refreshTokenService.getRefreshToken();
      final user = await userStorageService.getUser();

      if (!context.mounted) return;
      _isLoading = false;
      notifyListeners();

      if (accessToken != null && accessToken.isNotEmpty) {
        context.go('/home');
        return;
      }

      if ((refreshToken != null && refreshToken.isNotEmpty) || user != null) {
        // TODO: Refresh access token
        ErrorInterceptor.unauthenticatedStream.add('expired');
        context.go('/login');
        return;
      }

      // No session data at all -> unauthorized
      ErrorInterceptor.unauthenticatedStream.add('unauthorized');
      context.go('/login');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void retry(BuildContext context) {
    initialize(context);
  }
}
