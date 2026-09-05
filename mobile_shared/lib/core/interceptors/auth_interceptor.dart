import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/access_token_service.dart';

class AuthInterceptor extends Interceptor {
  static const _publicPaths = [
    '/auth/login',
    '/auth/login/google',
    '/auth/register',
    '/auth/refresh-token',
    '/auth/send-otp-register',
    '/auth/verify-otp-register',
    '/auth/send-otp-forgot-password',
    '/auth/reset-password',
  ];

  /// Kiểm tra path public endpoint
  bool _isPublicPath(String path) {
    return _publicPaths.any(
      (publicPath) => path == publicPath || path.startsWith('$publicPath/'),
    );
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    debugPrint('[AuthInterceptor] ENTER: ${options.method} $path');

    // Bypass
    if (_isPublicPath(path)) {
      debugPrint('[AuthInterceptor] SKIP (public endpoint): $path');
      super.onRequest(options, handler);
      return;
    }

    try {
      final token = await accessTokenService.getAccessToken();
      debugPrint(
        '[AuthInterceptor] token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}',
      );

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e, stackTrace) {
      debugPrint('▶ [AuthInterceptor] ERROR getting token: $e');
      debugPrint('▶ [AuthInterceptor] ERROR type: ${e.runtimeType}');
      debugPrint('▶ [AuthInterceptor] STACKTRACE: $stackTrace');
    }

    super.onRequest(options, handler);
  }
}
