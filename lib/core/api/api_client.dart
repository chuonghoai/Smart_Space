import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiClient {
  Future<T> get<T>(String url, {Options? options, Map<String, dynamic>? queryParameters}) async {
    final response = await dioInstance.get<T>(
      url,
      options: options,
      queryParameters: queryParameters,
    );
    return response.data as T;
  }

  Future<T> post<T>(String url, {dynamic data, Options? options}) async {
    final response = await dioInstance.post<T>(
      url,
      data: data,
      options: options,
    );
    return response.data as T;
  }

  Future<T> put<T>(String url, {dynamic data, Options? options}) async {
    final response = await dioInstance.put<T>(
      url,
      data: data,
      options: options,
    );
    return response.data as T;
  }

  Future<T> patch<T>(String url, {dynamic data, Options? options}) async {
    final response = await dioInstance.patch<T>(
      url,
      data: data,
      options: options,
    );
    return response.data as T;
  }

  Future<T> delete<T>(String url, {Options? options}) async {
    final response = await dioInstance.delete<T>(
      url,
      options: options,
    );
    return response.data as T;
  }
}

final apiClient = ApiClient();
