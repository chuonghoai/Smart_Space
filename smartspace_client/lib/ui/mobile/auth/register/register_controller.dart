import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';
import 'package:mobile_shared/util/device_info_util.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:mobile_shared/util/media_upload.dart';

class RegisterController extends ChangeNotifier {
  final AuthService _authService;
  final MediaUploadUtil _mediaUploadUtil;

  RegisterController({AuthService? service, MediaUploadUtil? mediaUpload})
    : _authService = service ?? authService,
      _mediaUploadUtil = mediaUpload ?? mediaUploadUtil;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Email
  String _email = '';
  String get email => _email;

  // OTP
  String _otp = '';
  String get otp => _otp;

  // Avatar bytes
  Uint8List? _selectedAvatarBytes;
  Uint8List? get selectedAvatarBytes => _selectedAvatarBytes;

  String? _selectedAvatarName;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Step 1: Send OTP to email
  Future<void> sendOtp({
    required BuildContext context,
    required String emailInput,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (emailInput.trim().isEmpty) {
      _setError(l10n.pleaseEnterEmail);
      return;
    }

    _setLoading(true);
    _setError(null);
    _email = emailInput.trim();

    try {
      final response = await _authService.sendOtpRegister(_email);

      if (response.success) {
        if (context.mounted) {
          context.push(RouterPath.registerOtp);
        }
      } else {
        _setError(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to send OTP.',
        );
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Step 2: Verify OTP with email
  Future<void> verifyOtp({
    required BuildContext context,
    required String otpInput,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (otpInput.trim().isEmpty) {
      _setError(l10n.pleaseEnterOTP);
      return;
    }

    _setLoading(true);
    _setError(null);
    _otp = otpInput.trim();

    try {
      final response = await _authService.verifyOtpRegister(_email, _otp);

      if (response.success) {
        if (context.mounted) {
          context.push(RouterPath.registerPassword);
        }
      } else {
        _setError(
          response.message.isNotEmpty ? response.message : 'Invalid OTP.',
        );
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Step 3: Register account
  Future<void> registerAccount({
    required BuildContext context,
    required String password,
    required String confirmPassword,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _setError(l10n.pleaseEnterPassword);
      return;
    }

    if (password != confirmPassword) {
      _setError(l10n.passwordsDoNotMatch);
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final deviceName = await DeviceInfoUtil.getDeviceName();
      final platform = DeviceInfoUtil.getPlatform();

      final response = await _authService.register(
        _email,
        password,
        confirmPassword,
        deviceId,
        deviceName,
        platform,
      );

      if (response.success && response.data != null) {
        if (context.mounted) {
          context.go(RouterPath.completeProfile);
        }
      } else {
        _setError(
          response.message.isNotEmpty
              ? response.message
              : 'Registration failed.',
        );
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Step 4: Fill profile information
  Future<void> completeProfile({
    required BuildContext context,
    required String fullname,
    required String phone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (fullname.trim().isEmpty) {
      _setError(l10n.pleaseEnterFullName);
      return;
    }

    if (phone.trim().isEmpty) {
      _setError(l10n.pleaseEnterPhoneNumber);
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      String? avatarUrl;

      debugPrint('▶ [completeProfile] START');
      debugPrint('▶ [completeProfile] fullname: ${fullname.trim()}');
      debugPrint('▶ [completeProfile] phone: ${phone.trim()}');
      debugPrint(
        '▶ [completeProfile] hasAvatar: ${_selectedAvatarBytes != null}',
      );

      if (_selectedAvatarBytes != null) {
        debugPrint('▶ [completeProfile] Uploading avatar...');
        avatarUrl = await _mediaUploadUtil.uploadMedia(
          _selectedAvatarBytes!,
          _selectedAvatarName ?? 'avatar.jpg',
        );
        debugPrint('▶ [completeProfile] avatarUrl: $avatarUrl');
      }

      debugPrint('▶ [completeProfile] Calling updateProfile API...');
      final response = await _authService.updateProfile(
        fullname.trim(),
        phone.trim(),
        avatarUrl,
      );
      debugPrint('▶ [completeProfile] API response received');
      debugPrint('▶ [completeProfile] success: ${response.success}');
      debugPrint('▶ [completeProfile] message: ${response.message}');
      debugPrint('▶ [completeProfile] data: ${response.data}');

      if (response.success && response.data != null) {
        if (context.mounted) {
          reset();
          context.go(RouterPath.home);
        }
      } else {
        _setError(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update profile.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('▶ [completeProfile] EXCEPTION CAUGHT');
      debugPrint('▶ [completeProfile] error: $e');
      debugPrint('▶ [completeProfile] errorType: ${e.runtimeType}');
      debugPrint('▶ [completeProfile] stackTrace: $stackTrace');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Util: Reset state
  void reset() {
    _email = '';
    _otp = '';
    _selectedAvatarBytes = null;
    _selectedAvatarName = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Util: Select avatar
  Future<void> selectAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        _selectedAvatarBytes = await pickedFile.readAsBytes();
        _selectedAvatarName = pickedFile.name;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image: $e');
    }
  }
}

final registerController = RegisterController();
