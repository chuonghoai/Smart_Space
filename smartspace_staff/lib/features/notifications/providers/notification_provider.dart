import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_staff/features/notifications/models/notification_model.dart';
import 'package:smartspace_staff/features/notifications/services/notification_service.dart';

class NotificationState {
  final NotificationCountModel? countModel;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;
  
  final List<NotificationModel> notifications;
  final bool isLoadingNotifications;
  final String? notificationsError;
  final int currentPage;
  final bool hasMore;

  /// Bộ lọc "Chưa đọc". Thông báo vừa được đọc trong chế độ này vẫn ở lại danh sách (hiển thị đã đọc)
  /// tới lần tải lại kế tiếp, để danh sách không nhảy dưới tay người dùng.
  final bool unreadOnly;

  NotificationState({
    this.countModel,
    this.isLoading = false,
    this.error,
    this.lastFetched,
    this.notifications = const [],
    this.isLoadingNotifications = false,
    this.notificationsError,
    this.currentPage = 0,
    this.hasMore = true,
    this.unreadOnly = false,
  });

  /// [notificationsError] nhận function để có thể xoá lỗi (gán `null`) tường minh.
  NotificationState copyWith({
    NotificationCountModel? countModel,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
    List<NotificationModel>? notifications,
    bool? isLoadingNotifications,
    String? Function()? notificationsError,
    int? currentPage,
    bool? hasMore,
    bool? unreadOnly,
  }) {
    return NotificationState(
      countModel: countModel ?? this.countModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
      notifications: notifications ?? this.notifications,
      isLoadingNotifications: isLoadingNotifications ?? this.isLoadingNotifications,
      notificationsError: notificationsError != null ? notificationsError() : this.notificationsError,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  static const int _pageSize = 20;

  final NotificationService _service;

  /// Tăng mỗi lần tải lại trang đầu — response của lần tải cũ hơn (vd. bộ lọc trước) bị bỏ qua.
  int _requestId = 0;

  NotificationNotifier(this._service) : super(NotificationState()) {
    fetchCount();
  }

  Timer? _fetchCountTimer;

  Future<void> fetchCount({bool forceRefresh = false}) async {
    if (!forceRefresh && state.lastFetched != null) {
      final diff = DateTime.now().difference(state.lastFetched!);
      if (diff.inMinutes < 10) {
        return; 
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getUnreadCount();
      if (response.success && response.data != null) {
        state = state.copyWith(
          countModel: response.data,
          isLoading: false,
          lastFetched: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Đổi bộ lọc Tất cả / Chưa đọc → tải lại từ trang đầu, xoá danh sách của bộ lọc cũ.
  Future<void> setUnreadOnly(bool unreadOnly) async {
    if (unreadOnly == state.unreadOnly) return;
    state = state.copyWith(unreadOnly: unreadOnly, notifications: const [], hasMore: true);
    await fetchNotifications();
  }

  /// [loadMore] = false: tải lại trang đầu theo bộ lọc hiện tại (mở màn, kéo làm mới, đổi bộ lọc).
  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (loadMore && (state.isLoadingNotifications || !state.hasMore)) return;

    final requestId = loadMore ? _requestId : ++_requestId;
    final page = loadMore ? state.currentPage + 1 : 0;
    state = state.copyWith(isLoadingNotifications: true, notificationsError: () => null);

    try {
      final response = await _service.getMyNotifications(
        page: page,
        size: _pageSize,
        unreadOnly: state.unreadOnly,
      );
      if (!mounted || requestId != _requestId) return;
      if (response.success && response.data != null) {
        final newItems = response.data!;
        final loadedIds = loadMore ? state.notifications.map((n) => n.id).toSet() : const <String>{};
        state = state.copyWith(
          isLoadingNotifications: false,
          notifications: loadMore
              ? [...state.notifications, ...newItems.where((n) => !loadedIds.contains(n.id))]
              : newItems,
          currentPage: page,
          hasMore: newItems.length >= _pageSize,
        );
      } else {
        state = state.copyWith(
          isLoadingNotifications: false, 
          notificationsError: () => response.message,
        );
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoadingNotifications: false,
        notificationsError: () => e.toString(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _service.markAllAsRead();
      if (response.success) {
        // Update local state
        final updatedList = state.notifications.map((n) {
          if (!n.isRead) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              imageUrl: n.imageUrl,
              isRead: true,
              createdAt: n.createdAt,
              actionData: n.actionData,
            );
          }
          return n;
        }).toList();

        state = state.copyWith(
          notifications: updatedList,
          countModel: NotificationCountModel(notifNumber: 0),
        );
      }
    } catch (e) {
      // Ignore errors for now, or log them
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await _service.markAsRead(id);
      if (response.success) {
        final updatedList = state.notifications.map((n) {
          if (n.id == id && !n.isRead) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        final currentCount = state.countModel?.notifNumber ?? 0;
        final newCount = currentCount > 0 ? currentCount - 1 : 0;

        state = state.copyWith(
          notifications: updatedList,
          countModel: state.countModel != null ? NotificationCountModel(notifNumber: newCount) : null,
        );
      }
    } catch (e) {
      // Ignore errors for now
    }
  }

  void onNotificationReceived() {
    _fetchCountTimer?.cancel();
    _fetchCountTimer = Timer(const Duration(milliseconds: 1000), () {
      fetchCount(forceRefresh: true);
      // optionally fetchNotifications(loadMore: false); if user is on notification screen
    });
  }

  @override
  void dispose() {
    _fetchCountTimer?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(notificationService);
    });

