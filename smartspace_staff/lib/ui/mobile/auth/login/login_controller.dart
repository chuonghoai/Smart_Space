import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/core/constants/registration_status.dart';
import 'package:smartspace_staff/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in_pkg;
import 'package:smartspace_staff/core/config/env_config.dart';
import 'package:smartspace_staff/core/connection/connection_manager.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService;

  LoginController({AuthService? service})
    : _authService = service ?? authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> login({
    required BuildContext context,
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (email.trim().isEmpty || password.isEmpty) {
      _error = l10n.pleaseEnterEmailAndPassword;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email.trim(),
        password,
        rememberMe,
      );
      final response = result.response;

      if (response.success && response.data != null) {
        final registrationStatus = response.data!.registrationStatus;
        if (context.mounted) {
          if (registrationStatus == ERegistrationStatus.completed) {
            connectionManager.startConnections();
            context.go(RouterPath.home);
          } else {
            context.go(RouterPath.completeProfile);
          }
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Login failed. Please try again.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static bool _isGoogleInitialized = false;

  Future<void> loginWithGoogle(BuildContext context) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!_isGoogleInitialized) {
        await google_sign_in_pkg.GoogleSignIn.instance.initialize(
          clientId: kIsWeb ? EnvConfig.googleClientId : null,
          serverClientId: EnvConfig.googleClientId,
        );
        _isGoogleInitialized = true;
      }

      final google_sign_in_pkg.GoogleSignInAccount googleUser = await google_sign_in_pkg.GoogleSignIn.instance.authenticate();
      final google_sign_in_pkg.GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _error = 'Google login failed: ID Token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _authService.loginGoogle(idToken);
      final response = result.response;

      if (response.success && response.data != null) {
        final registrationStatus = response.data!.registrationStatus;
        if (context.mounted) {
          if (registrationStatus == ERegistrationStatus.completed) {
            connectionManager.startConnections();
            context.go(RouterPath.home);
          } else {
            context.go(RouterPath.completeProfile);
          }
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Login failed. Please try again.';
      }
    } on google_sign_in_pkg.GoogleSignInException catch (e) {
      if (e.code == google_sign_in_pkg.GoogleSignInExceptionCode.canceled) {
        // User canceled, just return silently
      } else {
        _error = 'Google login error: ${e.code.name} - ${e.toString()}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
