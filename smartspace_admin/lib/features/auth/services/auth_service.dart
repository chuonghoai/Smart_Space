import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/auth/access_token_service.dart';
import 'package:mobile_shared/core/auth/refresh_token_service.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:mobile_shared/core/notification/firebase_service.dart';
import 'package:smartspace_admin/features/auth/models/token_model.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo_api.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo_mock.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:mobile_shared/core/connection/connection_manager.dart';

class AuthService {
  final AuthRepo authRepo;

  const AuthService({required this.authRepo});

  /// Login — trả về cả response và trạng thái kết nối WebSocket
  Future<({ApiResponse<TokenModel> response, bool wsConnected})> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    final response = await authRepo.login(email, password, rememberMe);
    final data = response.data;

    if (response.success &&
        data != null &&
        data.accessToken.isNotEmpty &&
        data.refreshToken.isNotEmpty) {
      await accessTokenService.saveAccessToken(data.accessToken);
      await refreshTokenService.saveRefreshToken(data.refreshToken);
      await userStorageService.saveUser(data.userModel!);

      // Kết nối WebSocket và FCM sẽ được xử lý ngầm trong LoginController
      return (response: response, wsConnected: true);
    }

    return (response: response, wsConnected: false);
  }

  Future<({ApiResponse<TokenModel> response, bool wsConnected})> loginGoogle(
    String idToken,
  ) async {
    final response = await authRepo.loginGoogle(idToken);
    final data = response.data;

    if (response.success &&
        data != null &&
        data.accessToken.isNotEmpty &&
        data.refreshToken.isNotEmpty) {
      await accessTokenService.saveAccessToken(data.accessToken);
      await refreshTokenService.saveRefreshToken(data.refreshToken);
      await userStorageService.saveUser(data.userModel!);

      return (response: response, wsConnected: true);
    }

    return (response: response, wsConnected: false);
  }

  Future<ApiResponse<void>> logout() async {
    try {
      return await authRepo.logout();
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Logout failed but cleared local data',
        data: null,
      );
    } finally {
      // Gọi API logout
      // Xóa FCM token của thiết bị hiện tại
      await FirebaseService.clearTokenOnServer();
      // Xóa token
      accessTokenService.clear();
      refreshTokenService.clear();
      userStorageService.clear();
      connectionManager.stopAllAndCleanUp();
    }
  }

  /// Refresh access token with refresh token in secured storage
  Future<bool> refreshToken(String refreshToken) async {
    try {
      final response = await authRepo.refreshToken(refreshToken);
      await accessTokenService.saveAccessToken(response.data!.accessToken);
      await refreshTokenService.saveRefreshToken(response.data!.refreshToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user profile and update local storage
  Future<UserModel?> getMe() async {
    try {
      final response = await authRepo.getMe();
      if (response.success && response.data != null) {
        await userStorageService.saveUser(response.data!);
        return response.data;
      }
    } catch (e) {
      // Ignore errors, return null
    }
    return null;
  }

  /// Register step 1: Send OTP with email
  Future<ApiResponse<void>> sendOtpRegister(String email) async {
    return await authRepo.sendOtpRegister(email);
  }

  /// Register step 2: Verify OTP with email
  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp) async {
    return await authRepo.verifyOtpRegister(email, otp);
  }

  /// Register step 3: Create account successfully with registrationStatus = incomplete
  Future<ApiResponse<TokenModel>> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    final response = await authRepo.register(email, password, confirmPassword);
    final data = response.data;

    if (response.success && data != null) {
      await accessTokenService.saveAccessToken(data.accessToken);
      await refreshTokenService.saveRefreshToken(data.refreshToken);
      await userStorageService.saveUser(data.userModel!);
    }

    return response;
  }

  /// Register step 4: Fill SDT and fullname to complete create account
  Future<ApiResponse<UserModel>> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
  ) async {
    final response = await authRepo.updateProfile(fullName, phone, avatarUrl);
    final data = response.data;

    if (response.success && data != null) {
      await userStorageService.saveUser(data);
    }

    return response;
  }

  /// Forgot password step 1: Send OTP to email
  Future<ApiResponse<void>> sendOtpForgotPassword(String email) async {
    return await authRepo.sendOtpForgotPassword(email);
  }

  /// Forgot password step 2: Reset password
  Future<ApiResponse<void>> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    return await authRepo.resetPassword(
      email,
      otp,
      newPassword,
      confirmPassword,
    );
  }

  /// Change password
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    return await authRepo.changePassword(
      currentPassword,
      newPassword,
      confirmPassword,
    );
  }
}

final authService = AuthService(
  authRepo: useMock ? AuthRepoMock() : AuthRepoApi(),
);
