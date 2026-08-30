// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:smartspace_client/core/auth/refresh_token_service.dart';
import 'package:smartspace_client/core/auth/access_token_service.dart';
import 'package:smartspace_client/core/auth/user_storage_service.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import '../../routes/app_router.dart';

class ErrorInterceptor extends Interceptor {
  static final StreamController<String> unauthenticatedStream =
      StreamController<String>.broadcast();

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
        appRouter.go(RouterPath.login);
        
        final context = navigatorKey.currentContext;
        if (context != null) {
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionExpired)),
            );
          }
        }
        return handler.next(err);
      }

      final refreshToken = await refreshTokenService.getRefreshToken();
      String reason = 'unauthorized';

      if (refreshToken != null) {
        bool refreshTokenSuccess = await authService.refreshToken(refreshToken);

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

      await authService.logout();
      unauthenticatedStream.add(reason);
      appRouter.go(RouterPath.login);
      return handler.next(err);
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
