import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/category_model.dart';

class CategoryRepository {
  Future<ApiResponse<List<CategoryModel>>> getCategories({
    bool activeOnly = false,
  }) {
    return apiClient.get(
      '/admin/categories',
      queryParameters: {'activeOnly': activeOnly},
      decoder: (json) => (json as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> _body({
    required String code,
    required String nameVi,
    required String nameEn,
    String? description,
    String? iconKey,
    required String defaultSeverity,
    bool? active,
    required int displayOrder,
    required List<String> positionIds,
  }) =>
      {
        'code': code,
        'nameVi': nameVi,
        'nameEn': nameEn,
        'description': description,
        'iconKey': iconKey,
        'defaultSeverity': defaultSeverity,
        'isActive': ?active,
        'displayOrder': displayOrder,
        'positionIds': positionIds,
      };

  Future<ApiResponse<CategoryModel>> createCategory({
    required String code,
    required String nameVi,
    required String nameEn,
    String? description,
    String? iconKey,
    required String defaultSeverity,
    required int displayOrder,
    required List<String> positionIds,
  }) {
    return apiClient.post(
      '/admin/categories',
      data: _body(
        code: code,
        nameVi: nameVi,
        nameEn: nameEn,
        description: description,
        iconKey: iconKey,
        defaultSeverity: defaultSeverity,
        active: true,
        displayOrder: displayOrder,
        positionIds: positionIds,
      ),
      decoder: (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CategoryModel>> updateCategory({
    required String id,
    required String code,
    required String nameVi,
    required String nameEn,
    String? description,
    String? iconKey,
    required String defaultSeverity,
    required bool active,
    required int displayOrder,
    required List<String> positionIds,
  }) {
    return apiClient.put(
      '/admin/categories/$id',
      data: _body(
        code: code,
        nameVi: nameVi,
        nameEn: nameEn,
        description: description,
        iconKey: iconKey,
        defaultSeverity: defaultSeverity,
        active: active,
        displayOrder: displayOrder,
        positionIds: positionIds,
      ),
      decoder: (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse> deleteCategory(String id) {
    return apiClient.delete('/admin/categories/$id');
  }
}

final categoryRepository = CategoryRepository();
