import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthService _authService;

  ForgotPasswordController({AuthService? service})
    : _authService = service ?? authService;

  bool _isSendingOtp = false;
  bool get isSendingOtp => _isSendingOtp;

  bool _isResettingPassword = false;
  bool get isResettingPassword => _isResettingPassword;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _otpSent = false;
  bool get otpSent => _otpSent;

  Future<void> sendOtp({
    required BuildContext context,
    required String email,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSendingOtp) return;

    if (email.trim().isEmpty) {
      _error = l10n.pleaseEnterEmail;
      notifyListeners();
      return;
    }

    _isSendingOtp = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _authService.sendOtpForgotPassword(email.trim());

      if (response.success) {
        _otpSent = true;
        _successMessage = l10n.otpSentSuccessfully;
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.otpSentSuccessfully)));
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : l10n.invalidEmail;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isResettingPassword) return;

    if (email.trim().isEmpty) {
      _error = l10n.pleaseEnterEmail;
      notifyListeners();
      return;
    }
    if (otp.trim().isEmpty) {
      _error = l10n.pleaseEnterOTP;
      notifyListeners();
      return;
    }
    if (newPassword.isEmpty) {
      _error = l10n.pleaseEnterPassword;
      notifyListeners();
      return;
    }
    if (confirmPassword.isEmpty) {
      _error = l10n.pleaseEnterConfirmPassword;
      notifyListeners();
      return;
    }
    if (newPassword != confirmPassword) {
      _error = l10n.passwordsDoNotMatch;
      notifyListeners();
      return;
    }

    _isResettingPassword = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _authService.resetPassword(
        email.trim(),
        otp.trim(),
        newPassword,
        confirmPassword,
      );

      if (response.success) {
        _successMessage = l10n.passwordResetSuccessfully;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.passwordResetSuccessfully)),
          );
          context.go(RouterPath.login);
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Error resetting password';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isResettingPassword = false;
      notifyListeners();
    }
  }
}
