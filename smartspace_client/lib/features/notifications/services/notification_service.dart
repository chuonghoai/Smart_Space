import 'package:smartspace_client/core/api/api_response.dart';
import 'package:smartspace_client/core/constants/use_mock.dart';
import 'package:smartspace_client/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_client/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_client/features/notifications/repositories/notification_repo_api.dart';
import 'package:smartspace_client/features/notifications/repositories/notification_repo_mock.dart';

class NotificationService {
  final NotificationRepo notificationRepo;

  const NotificationService({required this.notificationRepo});

  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return await notificationRepo.getUnreadCount();
  }
}

final notificationService = NotificationService(
  notificationRepo: useMock ? NotificationRepoMock() : NotificationRepoApi(),
);
