import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';

abstract class NotificationRepo {
  Future<ApiResponse<NotificationCountModel>> getUnreadCount();
}
