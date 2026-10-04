import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/position_model.dart';

class PositionRepository {
  Future<ApiResponse<List<PositionModel>>> getPositions({
    bool activeOnly = false,
  }) {
    return apiClient.get(
      '/admin/positions',
      queryParameters: {'activeOnly': activeOnly},
      decoder: (json) => (json as List)
          .map((e) => PositionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> _body(
    String code,
    String name,
    String? description,
    bool? active,
  ) =>
      {
        'code': code,
        'name': name,
        'description': description,
        if (active != null) 'isActive': active,
      };

  Future<ApiResponse> createPosition({
    required String code,
    required String name,
    String? description,
  }) {
    return apiClient.post(
      '/admin/positions',
      data: _body(code, name, description, true),
    );
  }

  Future<ApiResponse> updatePosition({
    required String id,
    required String code,
    required String name,
    String? description,
    required bool active,
  }) {
    return apiClient.put(
      '/admin/positions/$id',
      data: _body(code, name, description, active),
    );
  }

  Future<ApiResponse> deletePosition(String id) {
    return apiClient.delete('/admin/positions/$id');
  }
}

final positionRepository = PositionRepository();
