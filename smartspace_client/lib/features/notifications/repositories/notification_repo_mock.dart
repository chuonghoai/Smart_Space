import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_client/features/notifications/models/notification_model.dart';
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

  @override
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications({int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: [
        NotificationModel(
          id: '1',
          title: 'Test Notification',
          message: 'This is a mock notification',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    await Future.delayed(const Duration(seconds: 1));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: null,
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(
      success: true,
      message: 'Success',
      data: null,
    );
  }
}
