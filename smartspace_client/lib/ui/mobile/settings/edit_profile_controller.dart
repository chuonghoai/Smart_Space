import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartspace_client/core/auth/user_storage_service.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';
import 'package:smartspace_client/features/profile/models/user_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/util/media_upload.dart';

class EditProfileController extends ChangeNotifier {
  final AuthService _authService;
  final MediaUploadUtil _mediaUploadUtil;

  EditProfileController({AuthService? service, MediaUploadUtil? mediaUpload})
    : _authService = service ?? authService,
      _mediaUploadUtil = mediaUpload ?? mediaUploadUtil;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Avatar state — dùng Uint8List bytes để tương thích cả Mobile lẫn Web
  Uint8List? _selectedAvatarBytes;
  Uint8List? get selectedAvatarBytes => _selectedAvatarBytes;

  String? _selectedAvatarName;

  // Gender state
  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  Future<void> loadUser() async {
    _user = await userStorageService.getUser();
    _selectedGender = _user?.gender;
    notifyListeners();
  }

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  /// Chọn ảnh từ gallery/camera — đọc bytes thay vì tạo File
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
      _error = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required BuildContext context,
    required String fullName,
    required String phone,
    String? dateOfBirth,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    if (fullName.trim().isEmpty) {
      _error = l10n.pleaseEnterFullName;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? finalAvatarUrl = _user?.avatarUrl;

      if (_selectedAvatarBytes != null) {
        finalAvatarUrl = await _mediaUploadUtil.uploadMedia(
          _selectedAvatarBytes!,
          _selectedAvatarName ?? 'avatar.jpg',
        );
      }

      final response = await _authService.updateProfile(
        fullName.trim(),
        phone.trim(),
        finalAvatarUrl,
        dateOfBirth,
        _selectedGender,
      );

      if (response.success && response.data != null) {
        await userStorageService.saveUser(response.data!);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.profileUpdateSuccess)));
          Navigator.pop(context);
        }
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : l10n.profileUpdateFailed;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
