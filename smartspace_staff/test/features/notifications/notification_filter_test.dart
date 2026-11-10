import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_staff/features/notifications/models/notification_model.dart';
import 'package:smartspace_staff/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_staff/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_staff/features/notifications/services/notification_service.dart';

/// Repo giả: mỗi lần tải danh sách trả về một Completer để test điều khiển thứ tự response.
class _FakeNotificationRepo implements NotificationRepo {
  final List<({int page, bool unreadOnly})> calls = [];
  final List<Completer<ApiResponse<List<NotificationModel>>>> pending = [];

  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async =>
      ApiResponse(success: true, message: 'ok', data: NotificationCountModel(notifNumber: 2));

  @override
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications({
    int page = 0,
    int size = 20,
    bool unreadOnly = false,
  }) {
    calls.add((page: page, unreadOnly: unreadOnly));
    final completer = Completer<ApiResponse<List<NotificationModel>>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async => ApiResponse(success: true, message: 'ok');

  @override
  Future<ApiResponse<void>> markAllAsRead() async => ApiResponse(success: true, message: 'ok');
}

NotificationModel _notif(String id, {bool isRead = false}) =>
    NotificationModel(id: id, title: id, message: '', isRead: isRead, createdAt: DateTime(2026, 1, 1));

ApiResponse<List<NotificationModel>> _ok(List<NotificationModel> items) =>
    ApiResponse(success: true, message: 'ok', data: items);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeNotificationRepo repo;
  late NotificationNotifier notifier;

  setUp(() {
    repo = _FakeNotificationRepo();
    notifier = NotificationNotifier(NotificationService(notificationRepo: repo));
  });

  test('chọn "Chưa đọc" → tải lại trang 0 với unreadOnly, xoá danh sách cũ', () async {
    unawaited(notifier.fetchNotifications());
    await _flush();
    repo.pending.last.complete(_ok([_notif('a'), _notif('b', isRead: true)]));
    await _flush();

    unawaited(notifier.setUnreadOnly(true));
    await _flush();

    expect(repo.calls.last, (page: 0, unreadOnly: true));
    expect(notifier.state.notifications, isEmpty);
    expect(notifier.state.isLoadingNotifications, isTrue);
  });

  test('response của bộ lọc cũ về sau thì bị bỏ qua', () async {
    unawaited(notifier.fetchNotifications());
    await _flush();
    final allRequest = repo.pending.last;

    unawaited(notifier.setUnreadOnly(true));
    await _flush();
    repo.pending.last.complete(_ok([_notif('unread-1')]));
    await _flush();
    allRequest.complete(_ok([_notif('x'), _notif('y', isRead: true)]));
    await _flush();

    expect(notifier.state.notifications.map((n) => n.id), ['unread-1']);
    expect(notifier.state.unreadOnly, isTrue);
  });

  test('ở "Chưa đọc", đọc một thông báo thì nó vẫn ở lại danh sách (hiển thị đã đọc)', () async {
    unawaited(notifier.setUnreadOnly(true));
    await _flush();
    repo.pending.last.complete(_ok([_notif('a'), _notif('b')]));
    await _flush();

    await notifier.markAsRead('a');

    expect(notifier.state.notifications.map((n) => n.id), ['a', 'b']);
    expect(notifier.state.notifications.first.isRead, isTrue);
  });

  test('kéo làm mới và tải thêm giữ nguyên bộ lọc', () async {
    unawaited(notifier.setUnreadOnly(true));
    await _flush();
    repo.pending.last.complete(_ok(List.generate(20, (i) => _notif('n$i'))));
    await _flush();

    unawaited(notifier.fetchNotifications(loadMore: true));
    await _flush();
    expect(repo.calls.last, (page: 1, unreadOnly: true));
    repo.pending.last.complete(_ok([_notif('n20')]));
    await _flush();
    expect(notifier.state.hasMore, isFalse);

    unawaited(notifier.fetchNotifications());
    await _flush();
    expect(repo.calls.last, (page: 0, unreadOnly: true));
  });
}

