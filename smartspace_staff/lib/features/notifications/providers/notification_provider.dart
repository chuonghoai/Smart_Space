import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_staff/features/notifications/services/notification_service.dart';

class NotificationState {
  final NotificationCountModel? countModel;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;

  NotificationState({
    this.countModel,
    this.isLoading = false,
    this.error,
    this.lastFetched,
  });

  NotificationState copyWith({
    NotificationCountModel? countModel,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
  }) {
    return NotificationState(
      countModel: countModel ?? this.countModel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState()) {
    fetchCount();
  }

  Future<void> fetchCount({bool forceRefresh = false}) async {
    // Check TTL
    if (!forceRefresh && state.lastFetched != null) {
      final diff = DateTime.now().difference(state.lastFetched!);
      if (diff.inMinutes < 10) {
        return; // Use cache
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
}

// keepAlive is true by default when not using autoDispose
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(notificationService);
    });
