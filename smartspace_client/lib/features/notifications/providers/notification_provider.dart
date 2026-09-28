import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_client/features/notifications/models/notification_model.dart';
import 'package:smartspace_client/features/notifications/services/notification_service.dart';

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
  });

  NotificationState copyWith({
    NotificationCountModel? countModel,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
    List<NotificationModel>? notifications,
    bool? isLoadingNotifications,
    String? notificationsError,
    int? currentPage,
    bool? hasMore,
  }) {
    return NotificationState(
      countModel: countModel ?? this.countModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
      notifications: notifications ?? this.notifications,
      isLoadingNotifications: isLoadingNotifications ?? this.isLoadingNotifications,
      notificationsError: notificationsError ?? this.notificationsError,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

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

  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (state.isLoadingNotifications || (!state.hasMore && loadMore)) return;

    final page = loadMore ? state.currentPage + 1 : 0;
    state = state.copyWith(isLoadingNotifications: true, notificationsError: null);

    try {
      final response = await _service.getMyNotifications(page: page);
      if (response.success && response.data != null) {
        final newItems = response.data!;
        state = state.copyWith(
          isLoadingNotifications: false,
          notifications: loadMore ? [...state.notifications, ...newItems] : newItems,
          currentPage: page,
          hasMore: newItems.length >= 20,
        );
      } else {
        state = state.copyWith(
          isLoadingNotifications: false, 
          notificationsError: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingNotifications: false,
        notificationsError: e.toString(),
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
