import 'package:smartspace_client/core/api/api_response.dart';
import 'package:smartspace_client/core/constants/registration_status.dart';
import 'package:smartspace_client/core/constants/role_constant.dart';
import 'package:smartspace_client/core/storage/secured_storage.dart';
import 'package:smartspace_client/core/storage/shared_preferences.dart';
import 'package:smartspace_client/features/auth/models/token_model.dart';
import 'package:smartspace_client/features/auth/repositories/auth_repo.dart';
import 'package:smartspace_client/features/profile/models/user_model.dart';

class AuthRepoMock implements AuthRepo {
  @override
  Future<ApiResponse<TokenModel>> login(
    String email,
    String password,
    bool rememberMe,
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
  Future<ApiResponse<TokenModel>> loginGoogle(String idToken) async {
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
    String? avatarUrl,
  ) async {
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
}
