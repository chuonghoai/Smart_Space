import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';

final Dio dioInstance = Dio(
  BaseOptions(
    baseUrl: EnvConfig.apiUrl,
    connectTimeout: const Duration(milliseconds: EnvConfig.apiTimeout),
    receiveTimeout: const Duration(milliseconds: EnvConfig.apiTimeout),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
)..interceptors.addAll([
    AuthInterceptor(),
    ErrorInterceptor(),
  ]);
