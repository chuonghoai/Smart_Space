import 'package:mobile_shared/features/auth/models/DeviceSessionModel.dart';
import 'package:mobile_shared/features/auth/models/token_model.dart';
import 'package:mobile_shared/features/auth/repositories/auth_repo.dart';
import 'package:mobile_shared/mobile_shared.dart';

class AuthRepoApi implements AuthRepo {
  @override
  Future<ApiResponse<TokenModel>> login(
    String email,
    String password,
    bool rememberMe,
    String deviceId,
    String deviceName,
    String platform,
    ERole role,
  ) async {
    return await apiClient.post<TokenModel>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'role': role.name,
      },
      decoder: (json) => TokenModel.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<TokenModel>> loginGoogle(
    String idToken,
    String deviceId,
    String deviceName,
    String platform,
    ERole role,
  ) async {
    return await apiClient.post<TokenModel>(
      '/auth/login/google',
      data: {
        'idToken': idToken,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'role': role.name,
      },
      decoder: (json) => TokenModel.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<void>> logout() {
    return apiClient.post<void>('/auth/logout');
  }

  @override
  Future<ApiResponse<TokenModel>> refreshToken(String refreshToken) async {
    return await apiClient.post<TokenModel>(
      '/auth/refresh-token',
      data: {'refresh_token': refreshToken},
      decoder: (json) => TokenModel.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<UserModel>> getMe() async {
    return await apiClient.get<UserModel>(
      '/auth/me',
      decoder: (json) => UserModel.fromJson(json),
    );
  }

  // Step 1
  @override
  Future<ApiResponse<void>> sendOtpRegister(String email, ERole role) async {
    return await apiClient.post<void>(
      '/auth/send-otp-register',
      data: {'email': email, 'role': role.name},
    );
  }

  // Step 2
  @override
  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp, ERole role) async {
    return await apiClient.post<void>(
      '/auth/verify-otp-register',
      data: {'email': email, 'otp': otp, 'role': role.name},
    );
  }

  // Step 3
  @override
  Future<ApiResponse<TokenModel>> register(
    String email,
    String password,
    String confirmPassword,
    String deviceId,
    String deviceName,
    String platform,
    ERole role,
  ) async {
    return await apiClient.post<TokenModel>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'rememberMe': true,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'role': role.name,
      },
      decoder: (json) => TokenModel.fromJson(json),
    );
  }

  // Step 4
  @override
  Future<ApiResponse<UserModel>> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl, [
    String? dateOfBirth,
    String? gender,
  ]) async {
    return await apiClient.put<UserModel>(
      '/auth/update-profile',
      data: {
        'fullName': fullName,
        'phone': phone,
        'avatarUrl': avatarUrl,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
      },
      decoder: (json) => UserModel.fromJson(json),
    );
  }

  // Forgot password
  @override
  Future<ApiResponse<void>> sendOtpForgotPassword(String email) async {
    return await apiClient.post<void>(
      '/auth/send-otp-forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<ApiResponse<void>> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
    ERole role,
  ) async {
    return await apiClient.post<void>(
      '/auth/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
        'role': role.name,
      },
    );
  }

  // Đổi mật khẩu
  @override
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    return await apiClient.put<void>(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  //  Session Management
  @override
  Future<ApiResponse<List<DeviceSessionModel>>> getActiveSessions(
    String currentDeviceId,
  ) async {
    return await apiClient.get<List<DeviceSessionModel>>(
      '/auth/sessions',
      queryParameters: {'currentDeviceId': currentDeviceId},
      decoder: (json) =>
          (json as List).map((e) => DeviceSessionModel.fromJson(e)).toList(),
    );
  }

  @override
  Future<ApiResponse<void>> revokeSession(String deviceId) async {
    return await apiClient.delete<void>('/auth/sessions/$deviceId');
  }

  @override
  Future<ApiResponse<void>> revokeAllOtherSessions(
    String currentDeviceId,
  ) async {
    return await apiClient.delete<void>(
      '/auth/sessions',
      queryParameters: {'currentDeviceId': currentDeviceId},
    );
  }
}
