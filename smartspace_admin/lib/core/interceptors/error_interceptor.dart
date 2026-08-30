import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:smartspace_admin/core/auth/refresh_token_service.dart';
import 'package:smartspace_admin/core/storage/secured_storage.dart';
import '../../routes/app_router.dart';

class ErrorInterceptor extends Interceptor {
  static final StreamController<String> unauthenticatedStream =
      StreamController<String>.broadcast();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final requestUrl = err.requestOptions.path;

    if (status == 401 && !requestUrl.contains('/auth/login')) {
      final refreshToken = await refreshTokenService.getRefreshToken();
      String reason = 'unauthorized';
      if (refreshToken != null) {
        reason = 'expired';
      }

      await securedStorageService.clear();

      unauthenticatedStream.add(reason);
      appRouter.go('/login');
    }

    if (status == 403) {
      log('Forbidden');
      // TODO: add toast to notif error
    }

    if (status == 500) {
      log('Server error');
      // TODO: add toast to notif error
    }

    super.onError(err, handler);
  }
}
