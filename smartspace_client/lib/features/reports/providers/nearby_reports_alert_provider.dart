import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/reports/models/nearby_reports_alert_model.dart';
import 'package:smartspace_client/features/reports/presentation/widgets/nearby_reports_alert_modal.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

/// Periodic timer emitting every 15 minutes for nearby reports alert check
final nearbyAlertTimerProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();

  // Emit every 15 minutes
  final timer = Timer.periodic(const Duration(minutes: 15), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

class NearbyAlertsState {
  final bool isLoading;
  final NearbyReportsAlertResponse? lastAlert;
  final DateTime? lastCheckedTime;
  final Set<String> lastAlertedReportIds;

  const NearbyAlertsState({
    this.isLoading = false,
    this.lastAlert,
    this.lastCheckedTime,
    this.lastAlertedReportIds = const {},
  });

  NearbyAlertsState copyWith({
    bool? isLoading,
    NearbyReportsAlertResponse? lastAlert,
    DateTime? lastCheckedTime,
    Set<String>? lastAlertedReportIds,
  }) {
    return NearbyAlertsState(
      isLoading: isLoading ?? this.isLoading,
      lastAlert: lastAlert ?? this.lastAlert,
      lastCheckedTime: lastCheckedTime ?? this.lastCheckedTime,
      lastAlertedReportIds: lastAlertedReportIds ?? this.lastAlertedReportIds,
    );
  }
}

class NearbyReportsAlertNotifier extends StateNotifier<NearbyAlertsState> {
  final ReportService _reportService;
  final Ref? _ref;

  NearbyReportsAlertNotifier(this._reportService, [this._ref])
      : super(const NearbyAlertsState()) {
    // Listen to the 15-minute periodic timer if ref is provided
    _ref?.listen<AsyncValue<DateTime>>(nearbyAlertTimerProvider, (previous, next) {
      if (next.hasValue) {
        checkNearbyReportsAlert();
      }
    });
  }

  /// Checks nearby reports within 200m radius.
  /// If [notify] is false, backend will not broadcast notifications.
  /// If [forceShow] is true, shows modal if reports haven't been alerted yet.
  Future<NearbyReportsAlertResponse?> checkNearbyReportsAlert({
    Position? customPosition,
    bool forceShow = false,
    bool notify = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // 1. Validate device location service and permissions
      if (customPosition == null) {
        final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isLocationEnabled) {
          debugPrint('[NearbyAlerts] Location service is disabled on device. Skipping alert check.');
          state = state.copyWith(isLoading: false);
          return null;
        }

        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          debugPrint('[NearbyAlerts] Location permission is denied. Skipping alert check.');
          state = state.copyWith(isLoading: false);
          return null;
        }
      }

      // 2. Obtain current position
      final position = customPosition ?? await locationService.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      // 3. Fetch nearby active reports
      final res = await _reportService.getNearbyAlerts(
        lat: position.latitude,
        lng: position.longitude,
        radius: 200.0,
        notify: notify,
      );

      final alertData = res.data;
      if (alertData != null && alertData.count > 0 && alertData.reports.isNotEmpty) {
        final currentReportIds = alertData.reports.map((r) => r.id).toSet();

        // Check if there are new reports not yet alerted
        final hasNewReports = !state.lastAlertedReportIds.containsAll(currentReportIds);

        state = state.copyWith(
          isLoading: false,
          lastAlert: alertData,
          lastCheckedTime: DateTime.now(),
          lastAlertedReportIds: currentReportIds,
        );

        if (hasNewReports || forceShow) {
          final context = sharedNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            NearbyReportsAlertModal.show(context, alertData);
          }
        }

        return alertData;
      } else {
        state = state.copyWith(
          isLoading: false,
          lastCheckedTime: DateTime.now(),
        );
        return alertData;
      }
    } catch (e) {
      debugPrint('[NearbyAlerts] Error checking nearby alerts: $e');
      state = state.copyWith(isLoading: false);
      return null;
    }
  }
}

final nearbyReportsAlertProvider =
    StateNotifierProvider<NearbyReportsAlertNotifier, NearbyAlertsState>((ref) {
  return NearbyReportsAlertNotifier(reportService, ref);
});
