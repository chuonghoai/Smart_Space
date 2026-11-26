import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_staff/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final List<ReportModel> assignedReports;
  final ReportStatisticsModel? statistics;
  
  // New states for GPS and filters
  final Position? currentPosition;
  final String? gpsError;
  final String filterStatus;

  HomeState({
    this.isLoading = false,
    this.user,
    this.error,
    this.assignedReports = const [],
    this.statistics,
    this.currentPosition,
    this.gpsError,
    this.filterStatus = 'all',
  });

  HomeState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    List<ReportModel>? assignedReports,
    ReportStatisticsModel? statistics,
    Position? currentPosition,
    String? gpsError,
    String? filterStatus,
    bool clearGpsError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      assignedReports: assignedReports ?? this.assignedReports,
      statistics: statistics ?? this.statistics,
      currentPosition: currentPosition ?? this.currentPosition,
      gpsError: clearGpsError ? null : (gpsError ?? this.gpsError),
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  final Ref ref;
  Timer? _gpsTimer;

  HomeController(this.ref) : super(HomeState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _initGps();
    await _fetchData();
  }
  
  Future<void> _initGps() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Initial Permission Check & Prompt (Only happens once on init)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(gpsError: 'gpsError');
      // we still start the timer, if user enables it later, it will pick it up
    } else {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(gpsError: 'gpsError');
      }
    }
    
    // Initial fetch
    await _updateLocationQuietly();
    
    // Set up timer to update location every 10s internally
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocationQuietly();
    });
  }

  Future<void> _updateLocationQuietly() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) state = state.copyWith(gpsError: 'gpsError');
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) state = state.copyWith(gpsError: 'gpsError');
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        state = state.copyWith(currentPosition: position, clearGpsError: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(gpsError: 'gpsError');
      }
    }
  }

  Future<void> setFilter(String status) async {
    if (state.filterStatus == status) return;
    state = state.copyWith(filterStatus: status, isLoading: true);
    await _fetchData();
  }

  Future<void> manualRefresh() async {
    state = state.copyWith(isLoading: true);
    // Update location immediately on manual refresh
    await _updateLocationQuietly();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = await userStorageService.getUser();

      // Fetch assigned reports with limit 6 per requirement
      final reportsResponse = await reportService.getStaffAssignedReports(
        status: state.filterStatus,
        limit: 6,
      );

      // Fetch statistics
      final statsResponse = await reportService.getStaffStatistics();

      // Also refresh unread notification count
      ref.read(notificationProvider.notifier).fetchCount(forceRefresh: true);

      if (mounted) {
        state = state.copyWith(
          user: user,
          assignedReports: reportsResponse.success ? reportsResponse.data : [],
          statistics: statsResponse.success ? statsResponse.data : null,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }
}

final homeControllerProvider =
    StateNotifierProvider.autoDispose<HomeController, HomeState>((ref) {
  final link = ref.keepAlive();
  Timer? timer;
  
  // When there are no listeners, start the 15m timer
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 15), () {
      link.close();
    });
  });
  
  // If a listener is added before the timer expires, cancel the timer
  ref.onResume(() {
    timer?.cancel();
  });
  
  ref.onDispose(() {
    timer?.cancel();
  });
  
  return HomeController(ref);
});
