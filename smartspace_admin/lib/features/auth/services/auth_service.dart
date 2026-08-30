import 'package:smartspace_admin/core/api/api_response.dart';
import 'package:smartspace_admin/core/auth/access_token_service.dart';
import 'package:smartspace_admin/core/auth/refresh_token_service.dart';
import 'package:smartspace_admin/core/auth/user_storage_service.dart';
import 'package:smartspace_admin/core/constants/use_mock.dart';
import 'package:smartspace_admin/features/auth/models/token_model.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo_api.dart';
import 'package:smartspace_admin/features/auth/repositories/auth_repo_mock.dart';
import 'package:smartspace_admin/features/profile/models/user_model.dart';

class AuthService {
  final AuthRepo authRepo;

  const AuthService({required this.authRepo});

  Future<ApiResponse<TokenModel>> login(
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
      await Future.wait([
        accessTokenService.saveAccessToken(data.accessToken),
        refreshTokenService.saveRefreshToken(data.refreshToken),
        userStorageService.saveUser(data.userModel!),
      ]);
    }

    return response;
  }

  Future<ApiResponse<void>> logout() {
    accessTokenService.clear();
    refreshTokenService.clear();
    userStorageService.clear();
    return authRepo.logout();
  }

  Future<ApiResponse<TokenModel>> refreshToken(String refreshToken) async {
    return await authRepo.refreshToken(refreshToken);
  }

  Future<ApiResponse<void>> sendOtpRegister(String email) async {
    return await authRepo.sendOtpRegister(email);
  }

  Future<ApiResponse<void>> verifyOtpRegister(String email, String otp) async {
    return await authRepo.verifyOtpRegister(email, otp);
  }

  Future<ApiResponse<TokenModel>> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    return await authRepo.register(email, password, confirmPassword);
  }

  Future<ApiResponse<UserModel>> updateProfile(
    String fullName,
    String phone,
    String? avatarUrl,
  ) async {
    return await authRepo.updateProfile(fullName, phone, avatarUrl);
  }
}

final authService = AuthService(
  authRepo: useMock ? AuthRepoMock() : AuthRepoApi(),
);
