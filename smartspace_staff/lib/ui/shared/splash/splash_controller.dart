import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/constants/registration_status.dart';
import 'package:mobile_shared/core/auth/access_token_service.dart';
import 'package:mobile_shared/core/auth/refresh_token_service.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/core/interceptors/error_interceptor.dart';
import 'package:mobile_shared/core/localization/locale_provider.dart';
import 'package:mobile_shared/core/theme/theme_provider.dart';
import 'package:smartspace_staff/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:mobile_shared/core/connection/connection_manager.dart';

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

      // Access token valid -> getMe -> /home or /complete-profile
      if (accessToken != null && accessToken.isNotEmpty) {
        final currentUser = await authService.getMe();
        await locationService.getCurrentPosition();
        if (!context.mounted) return;

        if (currentUser?.registrationStatus == ERegistrationStatus.completed) {
          connectionManager.startConnections();
          context.go(RouterPath.home);
        } else {
          context.go(RouterPath.completeProfile);
        }
        return;
      }

      // Access token invalid && refresh token valid -> refresh access token -> getMe -> /home or /complete-profile
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
          final currentUser = await authService.getMe();
          await locationService.getCurrentPosition();
          if (!context.mounted) return;

          if (currentUser?.registrationStatus ==
              ERegistrationStatus.completed) {
            connectionManager.startConnections();
            context.go(RouterPath.home);
          } else {
            context.go(RouterPath.completeProfile);
          }
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
