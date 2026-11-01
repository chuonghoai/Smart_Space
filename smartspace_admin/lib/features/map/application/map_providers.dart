import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/storage/shared_preferences.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/features/reports/data/report_repository.dart';
import '../models/map_report_model.dart';
import '../models/report_density_model.dart';
import '../models/report_timeframe.dart';
import '../services/map_service.dart';

// Filter

final mapFilterProvider = StateProvider<ReportFilter>(
  (ref) => const ReportFilter(size: 500),
);

// Map Reports

class AdminMapReportsState {
  final List<MapReportModel> reports;
  final bool truncated;
  final bool isLoading;
  final String? error;
  final ReportTimeframe timeframe;

  const AdminMapReportsState({
    this.reports = const [],
    this.truncated = false,
    this.isLoading = false,
    this.error,
    this.timeframe = ReportTimeframe.all,
  });

  AdminMapReportsState copyWith({
    List<MapReportModel>? reports,
    bool? truncated,
    bool? isLoading,
    String? error,
    bool clearError = false,
    ReportTimeframe? timeframe,
  }) {
    return AdminMapReportsState(
      reports: reports ?? this.reports,
      truncated: truncated ?? this.truncated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      timeframe: timeframe ?? this.timeframe,
    );
  }
}

final mapReportsProvider =
    NotifierProvider<MapReportsNotifier, AdminMapReportsState>(MapReportsNotifier.new);

/// Report trên bản đồ Admin, tải theo khung nhìn + bộ lọc.
/// Quy tắc khi nào tải lại nằm ở [ViewportLoadGate] (dùng chung với Client).
/// Giữ dữ liệu cũ trong lúc tải → bản đồ không bị dựng lại, camera giữ nguyên.
class MapReportsNotifier extends Notifier<AdminMapReportsState> {
  static const String _prefKeyTimeframe = 'map_report_timeframe';
  static const int limit = 500;

  final MapService _service;
  final ViewportLoadGate _gate;

  MapReportsNotifier({MapService? service, DateTime Function()? now})
      : _service = service ?? mapService,
        _gate = ViewportLoadGate(now: now);

  @override
  AdminMapReportsState build() {
    // Đổi bộ lọc → dữ liệu đã tải không còn đúng, tải lại ngay khung đang xem
    ref.listen(mapFilterProvider, (_, _) {
      _gate.invalidate();
      refresh();
    });
    _loadPreference();
    return const AdminMapReportsState();
  }

  Future<void> _loadPreference() async {
    final tfCode = await sharedPreferencesService.get<String>(_prefKeyTimeframe);
    final tf = ReportTimeframe.fromCode(tfCode);
    if (tf != state.timeframe) {
      state = state.copyWith(timeframe: tf);
      await refresh();
    }
  }

  Future<void> setTimeframe(ReportTimeframe tf) async {
    if (state.timeframe == tf) return;
    _gate.invalidate();
    state = state.copyWith(timeframe: tf);
    unawaited(sharedPreferencesService.set(_prefKeyTimeframe, tf.code));
    await refresh();
  }

  Future<void> loadForViewport(MapBounds viewport, {bool force = false}) async {
    final request = _gate.begin(viewport, force: force);
    if (request == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final filter = ref.read(mapFilterProvider);
    final tf = filter.timeframe != null && filter.timeframe!.isNotEmpty
        ? filter.timeframe
        : state.timeframe.code;

    try {
      final response = await _service.getMapReports(
        status: filter.status,
        severity: filter.severity,
        assigneeId: filter.assigneeId,
        from: filter.from,
        to: filter.to,
        timeframe: tf,
        bounds: request.bounds,
        limit: limit,
      );
      if (!_gate.isCurrent(request)) return;

      final data = response.data;
      if (response.success && data != null) {
        _gate.succeed(request, truncated: data.truncated);
        state = state.copyWith(
          reports: data.reports,
          truncated: data.truncated,
          isLoading: false,
          clearError: true,
        );
      } else {
        _gate.fail(request);
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (!_gate.isCurrent(request)) return;
      _gate.fail(request);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Tải lại khung nhìn gần nhất, bỏ qua cache (vd. sau khi phân công).
  Future<void> refresh() async {
    final viewport = _gate.lastViewport;
    if (viewport == null) return;
    await loadForViewport(viewport, force: true);
  }
}

// Density State & Notifier

class AdminReportDensityState {
  final bool isEnabled;
  final bool isLoading;
  final bool truncated;
  final List<ReportDensityCell> cells;
  final String? geojsonString;
  final String? error;
  final ReportTimeframe timeframe;

  const AdminReportDensityState({
    this.isEnabled = false,
    this.isLoading = false,
    this.truncated = false,
    this.cells = const [],
    this.geojsonString,
    this.error,
    this.timeframe = ReportTimeframe.all,
  });

  AdminReportDensityState copyWith({
    bool? isEnabled,
    bool? isLoading,
    bool? truncated,
    List<ReportDensityCell>? cells,
    String? geojsonString,
    bool clearGeojson = false,
    String? error,
    bool clearError = false,
    ReportTimeframe? timeframe,
  }) {
    return AdminReportDensityState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      truncated: truncated ?? this.truncated,
      cells: cells ?? this.cells,
      geojsonString: clearGeojson ? null : (geojsonString ?? this.geojsonString),
      error: clearError ? null : (error ?? this.error),
      timeframe: timeframe ?? this.timeframe,
    );
  }
}

class AdminReportDensityNotifier extends StateNotifier<AdminReportDensityState> {
  static const String _prefKey = 'map_show_density';
  static const String _prefKeyTimeframe = 'map_report_timeframe';
  static const Duration freshness = Duration(minutes: 2);
  static const double prefetchFactor = 1.3;

  final MapService _service;
  final ViewportLoadGate _gate;
  MapBounds? _currentBounds;
  double _currentZoom = 14.0;
  int _activeRequestId = 0;

  AdminReportDensityNotifier(this._service)
      : _gate = ViewportLoadGate(prefetchFactor: prefetchFactor, freshness: freshness),
        super(const AdminReportDensityState()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await sharedPreferencesService.get<bool>(_prefKey) ?? false;
    final tfCode = await sharedPreferencesService.get<String>(_prefKeyTimeframe);
    final tf = ReportTimeframe.fromCode(tfCode);
    state = state.copyWith(isEnabled: enabled, timeframe: tf);
    if (enabled && _currentBounds != null) {
      await loadForViewport(_currentBounds!, _currentZoom, force: true);
    }
  }

  Future<void> setTimeframe(ReportTimeframe tf) async {
    if (state.timeframe == tf) return;
    _gate.invalidate();
    state = state.copyWith(timeframe: tf);
    unawaited(sharedPreferencesService.set(_prefKeyTimeframe, tf.code));
    if (state.isEnabled && _currentBounds != null) {
      await loadForViewport(_currentBounds!, _currentZoom, force: true);
    }
  }

  Future<void> toggleEnabled({MapBounds? bounds, double? zoom}) async {
    final newEnabled = !state.isEnabled;
    await sharedPreferencesService.set(_prefKey, newEnabled);
    if (!newEnabled) {
      _gate.invalidate();
      state = state.copyWith(
        isEnabled: false,
        cells: const [],
        clearGeojson: true,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(isEnabled: true);
      final b = bounds ?? _currentBounds;
      final z = zoom ?? _currentZoom;
      if (b != null) {
        await loadForViewport(b, z, force: true);
      }
    }
  }

  Future<void> loadForViewport(MapBounds bounds, double zoom, {bool force = false}) async {
    _currentBounds = bounds;
    _currentZoom = zoom;

    if (!state.isEnabled) return;

    final request = _gate.begin(bounds, force: force);
    if (request == null) return;

    final requestId = ++_activeRequestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getReportDensity(
        north: bounds.maxLat,
        south: bounds.minLat,
        east: bounds.maxLng,
        west: bounds.minLng,
        zoom: zoom,
        timeframe: state.timeframe.code,
      );

      if (!mounted || requestId != _activeRequestId || !_gate.isCurrent(request)) return;

      final data = response.data;
      if (response.success && data != null) {
        _gate.succeed(request, truncated: data.truncated);
        state = state.copyWith(
          isLoading: false,
          truncated: data.truncated,
          cells: data.cells,
          geojsonString: data.geojsonString,
          clearError: true,
        );
      } else {
        _gate.fail(request);
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (!mounted || requestId != _activeRequestId || !_gate.isCurrent(request)) return;
      _gate.fail(request);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminReportDensityProvider =
    StateNotifierProvider<AdminReportDensityNotifier, AdminReportDensityState>((ref) {
  return AdminReportDensityNotifier(mapService);
});

// Staff list for filter dropdown

final mapStaffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final res = await reportRepository.getStaffs();
  if (res.success && res.data != null) return res.data!;
  return [];
});
