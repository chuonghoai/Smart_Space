import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:mobile_shared/core/auth/refresh_token_service.dart';
import 'package:mobile_shared/core/auth/access_token_service.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';

class ErrorInterceptor extends Interceptor {
  static final StreamController<String> unauthenticatedStream =
      StreamController<String>.broadcast();

  static Future<bool> Function(String)? onRefreshToken;
  static Future<void> Function()? onLogout;

  static int _refreshCount = 0;
  static DateTime _lastRefreshTime = DateTime.now();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final requestUrl = err.requestOptions.path;

    if (status == 401 &&
        !requestUrl.contains('/auth/login') &&
        !requestUrl.contains('/auth/refresh-token') &&
        !requestUrl.contains('/auth/logout') &&
        !requestUrl.contains('/devices/fcm-token') &&
        err.requestOptions.extra['isRetry'] != true) {
      
      final now = DateTime.now();
      if (now.difference(_lastRefreshTime).inSeconds <= 3) {
        _refreshCount++;
      } else {
        _refreshCount = 1;
        _lastRefreshTime = now;
      }

      if (_refreshCount > 5) {
        await accessTokenService.clear();
        await refreshTokenService.clear();
        await userStorageService.clear();
        
        unauthenticatedStream.add('session_expired');
        return handler.next(err);
      }

      final refreshToken = await refreshTokenService.getRefreshToken();
      String reason = 'unauthorized';

      if (refreshToken != null && onRefreshToken != null) {
        bool refreshTokenSuccess = await onRefreshToken!(refreshToken);

        if (refreshTokenSuccess) {
          try {
            final newAccessToken = await accessTokenService.getAccessToken();
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            err.requestOptions.extra['isRetry'] = true;
            final dio = Dio();
            final response = await dio.fetch(err.requestOptions);
            return handler.resolve(response);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          } catch (e) {
            return handler.next(err);
          }
        }

        reason = 'expired';
      }

      if (onLogout != null) {
        await onLogout!();
      } else {
        await accessTokenService.clear();
        await refreshTokenService.clear();
        await userStorageService.clear();
      }
      unauthenticatedStream.add(reason);
      return handler.next(err);
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
