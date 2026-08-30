import 'package:flutter/material.dart';
import 'package:smartspace_staff/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class ChangePasswordController extends ChangeNotifier {
  final AuthService _authService;

  ChangePasswordController({AuthService? service})
    : _authService = service ?? authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // Password visibility toggles
  bool _obscureCurrent = true;
  bool get obscureCurrent => _obscureCurrent;

  bool _obscureNew = true;
  bool get obscureNew => _obscureNew;

  bool _obscureConfirm = true;
  bool get obscureConfirm => _obscureConfirm;

  void toggleObscureCurrent() {
    _obscureCurrent = !_obscureCurrent;
    notifyListeners();
  }

  void toggleObscureNew() {
    _obscureNew = !_obscureNew;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  Future<void> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    // Validation
    if (currentPassword.isEmpty) {
      _error = l10n.pleaseEnterCurrentPassword;
      notifyListeners();
      return;
    }
    if (newPassword.isEmpty) {
      _error = l10n.pleaseEnterNewPassword;
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
    if (!_isPasswordValid(newPassword)) {
      _error = l10n.passwordRequirementsNotMet;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _authService.changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );

      if (response.success) {
        _successMessage = l10n.changePasswordSuccess;
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.changePasswordSuccess)));
          Navigator.pop(context);
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : l10n.changePasswordFailed;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isPasswordValid(String password) {
    if (password.length < 8 || password.length > 20) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[!@#$^()_]'))) return false;
    return true;
  }
}
