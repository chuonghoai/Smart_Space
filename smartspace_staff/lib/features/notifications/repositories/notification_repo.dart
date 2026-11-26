import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_staff/features/notifications/models/notification_model.dart';

abstract class NotificationRepo {
  Future<ApiResponse<NotificationCountModel>> getUnreadCount();
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications({int page = 0, int size = 20});
  Future<ApiResponse<void>> markAllAsRead();
  Future<ApiResponse<void>> markAsRead(String id);
}

