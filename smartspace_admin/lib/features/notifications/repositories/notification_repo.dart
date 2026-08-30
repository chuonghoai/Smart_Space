import 'package:smartspace_admin/core/api/api_response.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';

abstract class NotificationRepo {
  Future<ApiResponse<NotificationCountModel>> getUnreadCount();
}
