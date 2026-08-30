import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/access_token_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    debugPrint('▶ [AuthInterceptor] ENTER: ${options.method} ${options.path}');
    try {
      final token = await accessTokenService.getAccessToken();
      debugPrint('▶ [AuthInterceptor] token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

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
