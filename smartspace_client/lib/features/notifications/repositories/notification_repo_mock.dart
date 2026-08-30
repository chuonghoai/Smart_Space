import 'package:smartspace_client/core/api/api_response.dart';
import 'package:smartspace_client/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_client/features/notifications/repositories/notification_repo.dart';

class NotificationRepoMock implements NotificationRepo {
  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: NotificationCountModel(notifNumber: 3), // Mock 3 unread
    );
  }
}
