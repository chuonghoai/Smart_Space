import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_response.dart';
import 'dio_client.dart';

class ApiClient {
  String _handleDioError(DioException e) {
    debugPrint('╔══════════════════════════════════════');
    debugPrint('║ DIO EXCEPTION DETAILS');
    debugPrint('╠══════════════════════════════════════');
    debugPrint('║ TYPE: ${e.type}');
    debugPrint('║ MESSAGE: ${e.message}');
    debugPrint('║ URI: ${e.requestOptions.uri}');
    debugPrint('║ METHOD: ${e.requestOptions.method}');
    debugPrint('║ HEADERS: ${e.requestOptions.headers}');
    debugPrint('║ DATA: ${e.requestOptions.data}');
    debugPrint('║ RESPONSE STATUS: ${e.response?.statusCode}');
    debugPrint('║ RESPONSE DATA: ${e.response?.data}');
    debugPrint('║ ORIGINAL ERROR: ${e.error}');
    debugPrint('║ ORIGINAL ERROR TYPE: ${e.error?.runtimeType}');
    debugPrint('║ STACKTRACE: ${e.stackTrace}');
    debugPrint('╚══════════════════════════════════════');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return "Hết thời gian kết nối. Vui lòng thử lại!";
    } else if (e.type == DioExceptionType.connectionError) {
      return "Không có kết nối mạng.";
    }
    
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.message ?? "Đã có lỗi xảy ra";
  }

  Future<ApiResponse<T>> get<T>(
    String url, {
    Options? options,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    try {
      final response = await dioInstance.get<Map<String, dynamic>>(
        url,
        options: options,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
        response.data!,
        decoder ?? (json) => json as T,
      );
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('╔══ NON-DIO ERROR ══════════════════');
      debugPrint('║ ERROR: $e');
      debugPrint('║ TYPE: ${e.runtimeType}');
      debugPrint('║ STACKTRACE: $stackTrace');
      debugPrint('╚══════════════════════════════════════');
      return ApiResponse<T>(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String url, {
    dynamic data,
    Options? options,
    T Function(dynamic)? decoder,
  }) async {
    try {
      final response = await dioInstance.post<Map<String, dynamic>>(
        url,
        data: data,
        options: options,
      );
      return ApiResponse.fromJson(
        response.data!,
        decoder ?? (json) => json as T,
      );
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('╔══ NON-DIO ERROR ══════════════════');
      debugPrint('║ ERROR: $e');
      debugPrint('║ TYPE: ${e.runtimeType}');
      debugPrint('║ STACKTRACE: $stackTrace');
      debugPrint('╚══════════════════════════════════════');
      return ApiResponse<T>(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String url, {
    dynamic data,
    Options? options,
    T Function(dynamic)? decoder,
  }) async {
    try {
      final response = await dioInstance.put<Map<String, dynamic>>(
        url,
        data: data,
        options: options,
      );
      return ApiResponse.fromJson(
        response.data!,
        decoder ?? (json) => json as T,
      );
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('╔══ NON-DIO ERROR ══════════════════');
      debugPrint('║ ERROR: $e');
      debugPrint('║ TYPE: ${e.runtimeType}');
      debugPrint('║ STACKTRACE: $stackTrace');
      debugPrint('╚══════════════════════════════════════');
      return ApiResponse<T>(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String url, {
    dynamic data,
    Options? options,
    T Function(dynamic)? decoder,
  }) async {
    try {
      final response = await dioInstance.patch<Map<String, dynamic>>(
        url,
        data: data,
        options: options,
      );
      return ApiResponse.fromJson(
        response.data!,
        decoder ?? (json) => json as T,
      );
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('╔══ NON-DIO ERROR ══════════════════');
      debugPrint('║ ERROR: $e');
      debugPrint('║ TYPE: ${e.runtimeType}');
      debugPrint('║ STACKTRACE: $stackTrace');
      debugPrint('╚══════════════════════════════════════');
      return ApiResponse<T>(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String url, {
    Options? options,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    try {
      final response = await dioInstance.delete<Map<String, dynamic>>(
        url,
        options: options,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(
        response.data!,
        decoder ?? (json) => json as T,
      );
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        data: null,
      );
    } catch (e, stackTrace) {
      debugPrint('╔══ NON-DIO ERROR ══════════════════');
      debugPrint('║ ERROR: $e');
      debugPrint('║ TYPE: ${e.runtimeType}');
      debugPrint('║ STACKTRACE: $stackTrace');
      debugPrint('╚══════════════════════════════════════');
      return ApiResponse<T>(
        success: false,
        message: e.toString(),
        data: null,
      );
    }
  }
}

final apiClient = ApiClient();
