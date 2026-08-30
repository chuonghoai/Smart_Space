import 'package:smartspace_staff/core/api/api_response.dart';
import 'package:smartspace_staff/features/auth/models/token_model.dart';
import 'package:smartspace_staff/features/profile/models/user_model.dart';

abstract class AuthRepo {
  Future<ApiResponse<TokenModel>> login(
    String email,
    String password,
    bool rememberMe,
  );

  Future<ApiResponse<TokenModel>> loginGoogle(String idToken);

  // Step 1: Nhập email, nhận OTP
  Future<ApiResponse<void>> sendOtpRegister(String email);
  // Step 2: Nhập OTP
  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp);
  // Step 3: Nhập mật khẩu
  Future<ApiResponse<TokenModel>> register(
    String email,
    String password,
    String confirmPassword,
  );
  // Step 4: Bổ sung thông tin (Nếu user thoát giữa chừng, tài khoản vẫn tồn tại và có thể đăng nhập)
  Future<ApiResponse<UserModel>> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
  );

  Future<ApiResponse<void>> logout();
  Future<ApiResponse<TokenModel>> refreshToken(String refreshToken);

  Future<ApiResponse<UserModel>> getMe();

  // Quên mật khẩu
  Future<ApiResponse<void>> sendOtpForgotPassword(String email);
  Future<ApiResponse<void>> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  );
  // Đổi mật khẩu
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
}
