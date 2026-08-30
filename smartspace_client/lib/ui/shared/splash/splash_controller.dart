import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/core/auth/access_token_service.dart';
import 'package:smartspace_client/core/auth/refresh_token_service.dart';
import 'package:smartspace_client/core/auth/user_storage_service.dart';
import 'package:smartspace_client/core/interceptors/error_interceptor.dart';
import 'package:smartspace_client/core/localization/locale_provider.dart';
import 'package:smartspace_client/core/theme/theme_provider.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/util/location_service.dart';
import 'package:smartspace_client/core/connection/connection_manager.dart';

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

      // Access token valid -> /home
      if (accessToken != null && accessToken.isNotEmpty) {
        await locationService.getCurrentPosition(); // Request location permission if not granted yet
        if (!context.mounted) return;
        connectionManager.startConnections();
        context.go(RouterPath.home);
        return;
      }

      // Access token invalid && refresh token valid -> refresh access token -> /home
      if (refreshToken != null && refreshToken.isNotEmpty) {
        bool success = false;
        try {
          success = await authService
              .refreshToken(refreshToken)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // Ignore timeout or other errors; fallback to login
        }
        if (!context.mounted) return;
        if (success) {
          await locationService.getCurrentPosition(); // Request location permission if not granted yet
          if (!context.mounted) return;
          connectionManager.startConnections();
          context.go(RouterPath.home);
          return;
        }
      }

      // AT, RT invalid && user valid -> logout -> /login
      if (user != null) {
        await authService.logout();
        if (!context.mounted) return;
        ErrorInterceptor.unauthenticatedStream.add('expired');
        context.go(RouterPath.login);
        return;
      }

      // No session data at all -> unauthorized -> /login
      ErrorInterceptor.unauthenticatedStream.add('unauthorized');
      context.go(RouterPath.login);
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
