import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/storage/shared_preferences.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';
import 'package:smartspace_client/features/reports/models/report_density_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class ReportDensityState {
  final bool isEnabled;
  final bool isLoading;
  final bool truncated;
  final List<ReportDensityCell> cells;
  final String? geojsonString;
  final String? error;

  const ReportDensityState({
    this.isEnabled = false,
    this.isLoading = false,
    this.truncated = false,
    this.cells = const [],
    this.geojsonString,
    this.error,
  });

  ReportDensityState copyWith({
    bool? isEnabled,
    bool? isLoading,
    bool? truncated,
    List<ReportDensityCell>? cells,
    String? geojsonString,
    bool clearGeojson = false,
    String? error,
    bool clearError = false,
  }) {
    return ReportDensityState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      truncated: truncated ?? this.truncated,
      cells: cells ?? this.cells,
      geojsonString: clearGeojson ? null : (geojsonString ?? this.geojsonString),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReportDensityNotifier extends StateNotifier<ReportDensityState> {
  static const String _prefKey = 'map_show_density';
  static const Duration freshness = Duration(minutes: 2);
  static const double prefetchFactor = 1.3;

  final ReportService _service;
  final ViewportLoadGate _gate;
  MapBounds? _currentBounds;
  double _currentZoom = 14.0;
  int _activeRequestId = 0;

  ReportDensityNotifier(this._service)
      : _gate = ViewportLoadGate(prefetchFactor: prefetchFactor, freshness: freshness),
        super(const ReportDensityState()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await sharedPreferencesService.get<bool>(_prefKey) ?? false;
    state = state.copyWith(isEnabled: enabled);
    if (enabled && _currentBounds != null) {
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

final reportDensityProvider =
    StateNotifierProvider<ReportDensityNotifier, ReportDensityState>((ref) {
  return ReportDensityNotifier(reportService);
});

