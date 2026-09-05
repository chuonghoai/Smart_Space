import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/registration_status.dart';
import 'package:mobile_shared/core/constants/role_constant.dart';
import 'package:mobile_shared/core/storage/secured_storage.dart';
import 'package:mobile_shared/core/storage/shared_preferences.dart';
import 'package:mobile_shared/features/auth/models/DeviceSessionModel.dart';
import 'package:mobile_shared/features/auth/models/token_model.dart';
import 'package:mobile_shared/features/auth/repositories/auth_repo.dart';
import 'package:mobile_shared/core/auth/models/user_model.dart';

class AuthRepoMock implements AuthRepo {
  @override
  Future<ApiResponse<TokenModel>> login(
    String email,
    String password,
    bool rememberMe,
    String deviceId,
    String deviceName,
    String platform,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'Đăng nhập thành công',
      data: TokenModel(
        accessToken: 'abcdanfnjkasnflasjnlfnsfl',
        refreshToken: 'rfjklanjfklanjslf',
        registrationStatus: ERegistrationStatus.completed,
        userModel: UserModel(
          id: 'abcd',
          email: 'trinhthy333@gmail.com',
          fullname: 'Hong Hac',
          avatarUrl: 'https://ui-avatars.com/api/?name=TH&format=png',
          role: ERole.client,
        ),
      ),
    );
  }

  @override
  Future<ApiResponse<TokenModel>> loginGoogle(
    String idToken,
    String deviceId,
    String deviceName,
    String platform,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'Đăng nhập Google thành công',
      data: TokenModel(
        accessToken: 'abcdanfnjkasnflasjnlfnsfl',
        refreshToken: 'rfjklanjfklanjslf',
        registrationStatus: ERegistrationStatus.completed,
        userModel: UserModel(
          id: 'abcd',
          email: 'trinhthy333@gmail.com',
          fullname: 'Hong Hac Google',
          avatarUrl: 'https://ui-avatars.com/api/?name=TH&format=png',
          role: ERole.client,
        ),
      ),
    );
  }

  @override
  Future<ApiResponse<void>> logout() async {
    await sharedPreferencesService.clear();
    await securedStorageService.clear();
    return ApiResponse(success: true, message: 'logout thanh cong', data: null);
  }

  @override
  Future<ApiResponse<TokenModel>> refreshToken(String refreshToken) async {
    return ApiResponse(
      success: true,
      message: 'cập nhật access token mới nhất',
      data: TokenModel(
        accessToken: 'abcdefeffefef',
        refreshToken: 'refreshToken',
      ),
    );
  }

  @override
  Future<ApiResponse<UserModel>> getMe() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'get me thành công',
      data: UserModel(
        id: 'abcd',
        email: 'trinhthy333@gmail.com',
        fullname: 'Hong Hac',
        avatarUrl: 'https://ui-avatars.com/api/?name=TH&format=png',
        role: ERole.client,
        registrationStatus: ERegistrationStatus.completed,
      ),
    );
  }

  // Step 1
  @override
  Future<ApiResponse<void>> sendOtpRegister(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'gửi mã otp thành công',
      data: null,
    );
  }

  // Step 2
  @override
  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'xác thực mã otp thành công',
      data: null,
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
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'đăng ký thành công',
      data: TokenModel(
        accessToken: 'abcdanfnjkasnflasjnlfnsfl',
        refreshToken: 'rfjklanjfklanjslf',
        registrationStatus: ERegistrationStatus.incomplete,
        userModel: UserModel(
          id: 'abcd',
          email: 'trinhthy333@gmail.com',
          fullname: 'Hong Hac',
          avatarUrl: 'https://ui-avatars.com/api/?name=TH&format=png',
          role: ERole.client,
        ),
      ),
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
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'cập nhật thông tin thành công',
      data: UserModel(
        id: 'abcd',
        email: 'trinhthy333@gmail.com',
        fullname: fullName,
        avatarUrl: 'https://ui-avatars.com/api/?name=TH&format=png',
        role: ERole.client,
      ),
    );
  }

  // Forgot password
  @override
  Future<ApiResponse<void>> sendOtpForgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'gửi otp thành công',
      data: null,
    );
  }

  @override
  Future<ApiResponse<void>> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'Đặt lại mật khẩu thành công, vui lòng đăng nhập lại',
      data: null,
    );
  }

  // Change password
  @override
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'Đổi mật khẩu thành công',
      data: null,
    );
  }

  // Session Management
  @override
  Future<ApiResponse<List<DeviceSessionModel>>> getActiveSessions(
    String currentDeviceId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: '',
      data: [
        DeviceSessionModel(
          sessionId: currentDeviceId,
          deviceName: 'Samsung Galaxy S24',
          platform: 'android',
          ipAddress: '192.168.1.10',
          isCurrentDevice: true,
          lastActiveAt: DateTime.now().millisecondsSinceEpoch,
        ),
        DeviceSessionModel(
          sessionId: 'dev-002',
          deviceName: 'Chrome trên Windows 11',
          platform: 'web',
          ipAddress: '118.69.45.12',
          isCurrentDevice: false,
          lastActiveAt: DateTime.now()
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
        ),
        DeviceSessionModel(
          sessionId: 'dev-003',
          deviceName: 'iPhone 15 Pro',
          platform: 'ios',
          ipAddress: '10.0.0.5',
          isCurrentDevice: false,
          lastActiveAt: DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<void>> revokeSession(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse(success: true, message: '', data: null);
  }

  @override
  Future<ApiResponse<void>> revokeAllOtherSessions(
    String currentDeviceId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse(success: true, message: '', data: null);
  }
}
