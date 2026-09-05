import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in_pkg;
import 'package:smartspace_client/core/config/env_config.dart';
import 'package:smartspace_client/core/connection/connection_manager.dart';
import 'package:smartspace_client/core/constants/registration_status.dart';
import 'package:smartspace_client/core/utils/device_info_util.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';

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
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final deviceName = await DeviceInfoUtil.getDeviceName();
      final platform = DeviceInfoUtil.getPlatform();

      final result = await _authService.login(
        email.trim(),
        password,
        rememberMe,
        deviceId,
        deviceName,
        platform,
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

  //  Google Sign-In
  static bool _isGoogleInitialized = false;

  /// Stream subscription cho Web authentication events
  StreamSubscription<google_sign_in_pkg.GoogleSignInAuthenticationEvent>?
  _webAuthSubscription;

  /// Context lưu tạm để Web callback có thể truy cập
  BuildContext? _pendingContext;

  /// Web: clientId = EnvConfig.googleClientId, serverClientId = null
  /// Mobile: clientId = null (lấy từ google-services.json), serverClientId = EnvConfig.googleClientId
  Future<void> initializeGoogleSignIn() async {
    if (_isGoogleInitialized) return;

    debugPrint('▶ [GoogleLogin] Initializing... kIsWeb=$kIsWeb');
    await google_sign_in_pkg.GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? EnvConfig.googleClientId : null,
      serverClientId: kIsWeb ? null : EnvConfig.googleClientId,
    );
    _isGoogleInitialized = true;
    debugPrint('▶ [GoogleLogin] Initialized successfully');
  }

  void listenForWebGoogleSignIn(BuildContext context) {
    if (!kIsWeb) return;

    _webAuthSubscription?.cancel();
    _pendingContext = context;

    _webAuthSubscription = google_sign_in_pkg
        .GoogleSignIn
        .instance
        .authenticationEvents
        .listen(
          (event) {
            if (event
                is google_sign_in_pkg.GoogleSignInAuthenticationEventSignIn) {
              debugPrint('▶ [GoogleLogin][Web] Received sign-in event');
              final ctx = _pendingContext;
              if (ctx != null && ctx.mounted) {
                _handleGoogleSignInAccount(ctx, event.user);
              }
            }
          },
          onError: (error) {
            debugPrint('▶ [GoogleLogin][Web] Auth stream error: $error');
            if (error is google_sign_in_pkg.GoogleSignInException) {
              if (error.code ==
                  google_sign_in_pkg.GoogleSignInExceptionCode.canceled) {
                debugPrint('▶ [GoogleLogin][Web] User cancelled');
              } else {
                _error = 'Google login error: ${error.code.name}';
                _isLoading = false;
                notifyListeners();
              }
            }
          },
        );
  }

  void stopListeningWebGoogleSignIn() {
    _webAuthSubscription?.cancel();
    _webAuthSubscription = null;
    _pendingContext = null;
  }

  /// Mobile
  Future<void> loginWithGoogle(BuildContext context) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // initialize
      await initializeGoogleSignIn();

      debugPrint('▶ [GoogleLogin][Mobile] Calling authenticate()...');
      final google_sign_in_pkg.GoogleSignInAccount googleUser =
          await google_sign_in_pkg.GoogleSignIn.instance.authenticate();

      debugPrint('▶ [GoogleLogin][Mobile] Got user: ${googleUser.email}');
      if (!context.mounted) return;
      await _handleGoogleSignInAccount(context, googleUser);
    } on google_sign_in_pkg.GoogleSignInException catch (e) {
      debugPrint('▶ [GoogleLogin][Mobile] Exception: ${e.code.name}');
      if (e.code == google_sign_in_pkg.GoogleSignInExceptionCode.canceled) {
        // User đã hủy
        debugPrint(
          '▶ [GoogleLogin][Mobile] User cancelled or config error. Check SHA-1 on Firebase.',
        );
      } else {
        _error = 'Google login error: ${e.code.name}';
      }
    } catch (e) {
      debugPrint('▶ [GoogleLogin][Mobile] Unexpected error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xử lý chung kết quả Google Sign-In (dùng cho cả Web và Mobile)
  Future<void> _handleGoogleSignInAccount(
    BuildContext context,
    google_sign_in_pkg.GoogleSignInAccount googleUser,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final google_sign_in_pkg.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint(
        '▶ [GoogleLogin] idToken: ${idToken != null ? "${idToken.substring(0, 20)}..." : "NULL"}',
      );

      if (idToken == null) {
        _error = 'Google login failed: ID Token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final deviceId = await DeviceInfoUtil.getDeviceId();
      final deviceName = await DeviceInfoUtil.getDeviceName();
      final platform = DeviceInfoUtil.getPlatform();

      debugPrint('▶ [GoogleLogin] Calling backend /auth/login/google...');
      final result = await _authService.loginGoogle(
        idToken,
        deviceId,
        deviceName,
        platform,
      );
      final response = result.response;

      if (response.success && response.data != null) {
        final registrationStatus = response.data!.registrationStatus;
        debugPrint(
          '▶ [GoogleLogin] Success! registrationStatus=$registrationStatus',
        );
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
      debugPrint('▶ [GoogleLogin] Backend call error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListeningWebGoogleSignIn();
    super.dispose();
  }
}
