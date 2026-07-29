import 'package:smartspace_admin/core/api/pagination.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T data;
  final Pagination? pagination;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: fromJsonT(json['data']),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}
