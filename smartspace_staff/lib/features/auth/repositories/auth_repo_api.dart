import 'package:smartspace_staff/core/api/api_client.dart';
import 'package:smartspace_staff/core/api/api_response.dart';
import 'package:smartspace_staff/features/auth/models/token_model.dart';
import 'package:smartspace_staff/features/auth/repositories/auth_repo.dart';
import 'package:smartspace_staff/features/profile/models/user_model.dart';

class AuthRepoApi implements AuthRepo {
  @override
  Future<ApiResponse<TokenModel>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    return await apiClient.post<TokenModel>(
      '/auth/login',
      data: {'email': email, 'password': password, 'rememberMe': rememberMe},
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

  // Step 1
  @override
  Future<ApiResponse<void>> sendOtpRegister(String email) async {
    return await apiClient.post<void>(
      '/auth/send-otp-register',
      data: {'email': email},
    );
  }

  // Step 2
  @override
  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp) async {
    return await apiClient.post<void>(
      '/auth/verify-otp-register',
      data: {'email': email, 'otp': otp},
    );
  }

  // Step 3
  @override
  Future<ApiResponse<TokenModel>> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    return await apiClient.post<TokenModel>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'rememberMe': true,
      },
      decoder: (json) => TokenModel.fromJson(json),
    );
  }

  // Step 4
  @override
  Future<ApiResponse<UserModel>> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
  ) async {
    return await apiClient.put<UserModel>(
      '/auth/update-profile',
      data: {'fullName': fullName, 'phone': phone, 'avatarUrl': avatarUrl},
      decoder: (json) => UserModel.fromJson(json),
    );
  }
}
