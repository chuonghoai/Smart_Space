import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class MapReportsState {
  final List<ReportModel> reports;
  final bool truncated;
  final bool isLoading;
  final String? error;

  const MapReportsState({
    this.reports = const [],
    this.truncated = false,
    this.isLoading = false,
    this.error,
  });

  MapReportsState copyWith({
    List<ReportModel>? reports,
    bool? truncated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MapReportsState(
      reports: reports ?? this.reports,
      truncated: truncated ?? this.truncated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Report trên bản đồ Client, tải theo khung nhìn.
/// Quy tắc khi nào tải lại nằm ở [ViewportLoadGate] (dùng chung với Admin).
/// Giữ dữ liệu cũ trong lúc tải → bản đồ không bị trống/nháy.
class MapReportsNotifier extends StateNotifier<MapReportsState> {
  static const double prefetchFactor = 1.5;
  static const Duration freshness = Duration(minutes: 2);
  static const int limit = 300;

  final ReportService _service;
  final ViewportLoadGate _gate;

  MapReportsNotifier(this._service, {DateTime Function()? now})
      : _gate = ViewportLoadGate(prefetchFactor: prefetchFactor, freshness: freshness, now: now),
        super(const MapReportsState());

  Future<void> loadForViewport(MapBounds viewport, {bool force = false}) async {
    final request = _gate.begin(viewport, force: force);
    if (request == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getReportsInBounds(request.bounds, limit: limit);
      if (!mounted || !_gate.isCurrent(request)) return;

      final data = response.data;
      if (response.success && data != null) {
        _gate.succeed(request, truncated: data.truncated);
        state = MapReportsState(
          reports: data.reports
              .where((r) => r.latitude != 0 || r.longitude != 0)
              .toList(),
          truncated: data.truncated,
        );
      } else {
        _gate.fail(request);
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (!mounted || !_gate.isCurrent(request)) return;
      _gate.fail(request);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Tải lại khung nhìn gần nhất, bỏ qua cache.
  Future<void> refresh() async {
    final viewport = _gate.lastViewport;
    if (viewport == null) return;
    await loadForViewport(viewport, force: true);
  }
}

final mapReportsProvider =
    StateNotifierProvider.autoDispose<MapReportsNotifier, MapReportsState>(
  (ref) => MapReportsNotifier(reportService),
);
