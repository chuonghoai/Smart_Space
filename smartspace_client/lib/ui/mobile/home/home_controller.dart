import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/core/auth/user_storage_service.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/features/profile/models/user_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_providers.dart';

class HomeState {
  final bool isLoading;
  final UserModel? user;
  final List<ReportModel> recentReports;
  final List<ReportModel> dangerousReports;
  final int unreadNotifications;
  final String? error;

  HomeState({
    this.isLoading = false,
    this.user,
    this.recentReports = const [],
    this.dangerousReports = const [],
    this.unreadNotifications = 0,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    UserModel? user,
    List<ReportModel>? recentReports,
    List<ReportModel>? dangerousReports,
    int? unreadNotifications,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      recentReports: recentReports ?? this.recentReports,
      dangerousReports: dangerousReports ?? this.dangerousReports,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      error: error ?? this.error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final Ref ref;

  HomeController(this.ref) : super(HomeState()) {
    _init();

    // Listen to report provider
    ref.listen<ReportsState>(reportsProvider, (previous, next) {
      state = state.copyWith(
        recentReports: next.recentReports,
        dangerousReports: next.dangerousReports,
        isLoading:
            next.isLoading &&
            state.user == null, // Only block if we have no initial data
        error: next.error,
      );
    });

    // Listen to notification provider
    ref.listen<NotificationState>(notificationProvider, (previous, next) {
      state = state.copyWith(
        unreadNotifications: next.countModel?.notifNumber ?? 0,
      );
    });
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = await userStorageService.getUser();
    state = state.copyWith(user: user, isLoading: false);
  }

  Future<void> manualRefresh() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      ref.read(reportsProvider.notifier).refreshAll(),
      ref.read(notificationProvider.notifier).fetchCount(forceRefresh: true),
    ]);
    state = state.copyWith(isLoading: false);
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref);
  },
);
