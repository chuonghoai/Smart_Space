import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';

import '../models/account_lock_request_model.dart';

class AccountLockRepository {
  /// [status]: 'pending' | 'resolved' | 'all'
  Future<ApiResponse<AccountLockRequestPage>> getRequests({
    required String status,
    int page = 1,
    int size = 10,
  }) {
    return apiClient.get(
      '/admin/lock-requests',
      queryParameters: {'status': status, 'page': page, 'size': size},
      decoder: (json) =>
          AccountLockRequestPage.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountLockRequestModel>> getRequest(String id) {
    return apiClient.get(
      '/admin/lock-requests/$id',
      decoder: (json) =>
          AccountLockRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountLockPendingCount>> getPendingCount() {
    return apiClient.get(
      '/admin/lock-requests/pending-count',
      decoder: (json) =>
          AccountLockPendingCount.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountLockRequestModel>> create({
    required String targetUserId,
    required String reason,
    required List<String> evidenceImageUrls,
    required List<String> reportIds,
  }) {
    return apiClient.post(
      '/admin/lock-requests',
      data: {
        'targetUserId': targetUserId,
        'reason': reason,
        'evidenceImageUrls': evidenceImageUrls,
        'reportIds': reportIds,
      },
      decoder: (json) =>
          AccountLockRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountLockRequestModel>> vote(
    String id, {
    required bool approve,
    String? comment,
  }) {
    return apiClient.post(
      '/admin/lock-requests/$id/votes',
      data: {
        'decision': approve ? 'approve' : 'reject',
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
      decoder: (json) =>
          AccountLockRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountLockRequestModel>> cancel(String id) {
    return apiClient.post(
      '/admin/lock-requests/$id/cancel',
      decoder: (json) =>
          AccountLockRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse> unlockUser(String userId, String reason) {
    return apiClient.put('/admin/users/$userId/unlock', data: {'reason': reason});
  }
}

final accountLockRepository = AccountLockRepository();
