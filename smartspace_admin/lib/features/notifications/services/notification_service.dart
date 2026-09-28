import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo_api.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo_mock.dart';

class NotificationService {
  final NotificationRepo notificationRepo;

  const NotificationService({required this.notificationRepo});

  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return await notificationRepo.getUnreadCount();
  }

  Future<ApiResponse<List<NotificationModel>>> getMyNotifications({int page = 0, int size = 20}) async {
    return await notificationRepo.getMyNotifications(page: page, size: size);
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    return await notificationRepo.markAllAsRead();
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    return await notificationRepo.markAsRead(id);
  }
}

final notificationService = NotificationService(
  notificationRepo: useMock ? NotificationRepoMock() : NotificationRepoApi(),
);

