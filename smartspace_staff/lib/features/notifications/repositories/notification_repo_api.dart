import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_staff/features/notifications/repositories/notification_repo.dart';

class NotificationRepoApi implements NotificationRepo {
  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return await apiClient.get<NotificationCountModel>(
      '/notifications/unread-count',
      decoder: (json) => NotificationCountModel.fromJson(json),
    );
  }
}
