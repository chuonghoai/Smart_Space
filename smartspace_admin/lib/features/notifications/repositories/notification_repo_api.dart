import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';

class NotificationRepoApi implements NotificationRepo {
  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return await apiClient.get<NotificationCountModel>(
      '/notifications/unread-count',
      decoder: (json) => NotificationCountModel.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications({int page = 0, int size = 20}) async {
    return await apiClient.get<List<NotificationModel>>(
      '/notifications/my?page=$page&size=$size',
      decoder: (json) {
        if (json['content'] != null && json['content'] is List) {
          return (json['content'] as List).map((e) => NotificationModel.fromJson(e)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    return await apiClient.put<void>(
      '/notifications/my/read-all',
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    return await apiClient.put<void>(
      '/notifications/$id/read',
    );
  }
}

