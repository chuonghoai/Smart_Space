import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/auth/refresh_token_service.dart';
import 'package:mobile_shared/core/auth/access_token_service.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:mobile_shared/core/api/dio_client.dart';

class ErrorInterceptor extends Interceptor {
  static final StreamController<String> unauthenticatedStream =
      StreamController<String>.broadcast();

  static int _refreshCount = 0;
  static DateTime _lastRefreshTime = DateTime.now();

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

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

      if (_isRefreshing) {
        final isSuccess = await _refreshCompleter!.future;
        if (isSuccess) {
          try {
            final newAccessToken = await accessTokenService.getAccessToken();
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            err.requestOptions.extra['isRetry'] = true;
            final response = await dioInstance.fetch(err.requestOptions);
            return handler.resolve(response);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          } catch (e) {
            return handler.next(err);
          }
        } else {
          return handler.next(err);
        }
      }

      _isRefreshing = true;
      _refreshCompleter = Completer<bool>();

      final refreshToken = await refreshTokenService.getRefreshToken();
      String reason = 'unauthorized';

      if (refreshToken != null) {
        bool refreshTokenSuccess = await authService.refreshToken(refreshToken);

        if (refreshTokenSuccess) {
          _isRefreshing = false;
          _refreshCompleter?.complete(true);

          try {
            final newAccessToken = await accessTokenService.getAccessToken();
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            err.requestOptions.extra['isRetry'] = true;
            final response = await dioInstance.fetch(err.requestOptions);
            debugPrint("Refreshed token success");
            return handler.resolve(response);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          } catch (e) {
            return handler.next(err);
          }
        }

        reason = 'expired';
      }

      _isRefreshing = false;
      _refreshCompleter?.complete(false);

      try {
        await authService.logout();
      } catch (_) {
        // Fallback clear
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
