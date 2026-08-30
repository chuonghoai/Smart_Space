import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';

final Dio dioInstance = Dio(
  BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
    receiveTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
)..interceptors.addAll([
    AuthInterceptor(),
    ErrorInterceptor(),
  ]);
