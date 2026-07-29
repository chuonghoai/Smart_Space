import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import '../../routes/app_router.dart';
import '../auth/token_service.dart';
import '../auth/user_storage_service.dart';

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
      final currentUser = await userStorageService.getUser();
      String reason = 'unauthorized';
      if (currentUser != null) {
        reason = 'expired';
      }

      await userStorageService.removeUser();
      await tokenService.clear();

      unauthenticatedStream.add(reason);
      appRouter.go('/login');
    }

    if (status == 403) {
      log('Forbidden');
    }

    if (status == 500) {
      log('Server error');
    }

    super.onError(err, handler);
  }
}
