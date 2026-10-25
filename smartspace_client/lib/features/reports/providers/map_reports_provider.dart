import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class MapReportsState {
  final List<ReportModel> reports;
  final bool truncated;
  final bool isLoading;
  final String? error;
  final MapBounds? fetchedBounds;
  final DateTime? fetchedAt;

  const MapReportsState({
    this.reports = const [],
    this.truncated = false,
    this.isLoading = false,
    this.error,
    this.fetchedBounds,
    this.fetchedAt,
  });

  MapReportsState copyWith({
    List<ReportModel>? reports,
    bool? truncated,
    bool? isLoading,
    String? error,
    bool clearError = false,
    MapBounds? fetchedBounds,
    DateTime? fetchedAt,
  }) {
    return MapReportsState(
      reports: reports ?? this.reports,
      truncated: truncated ?? this.truncated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fetchedBounds: fetchedBounds ?? this.fetchedBounds,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

/// Report trên bản đồ Client, tải theo khung nhìn.
///
/// - Tải khung rộng hơn màn hình ([prefetchFactor]) để kéo nhẹ không phải tải lại.
/// - Giữ dữ liệu cũ trong lúc tải → bản đồ không bị trống/nháy.
/// - Bỏ response của request cũ nếu đã có request mới hơn.
class MapReportsNotifier extends StateNotifier<MapReportsState> {
  static const double prefetchFactor = 1.5;
  static const Duration freshness = Duration(minutes: 2);
  static const int limit = 300;

  final ReportService _service;
  final DateTime Function() _now;

  int _requestId = 0;
  MapBounds? _lastViewport;
  MapBounds? _lastRequestedViewport;
  DateTime? _lastRequestedAt;

  MapReportsNotifier(this._service, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(const MapReportsState());

  Future<void> loadForViewport(MapBounds viewport, {bool force = false}) async {
    _lastViewport = viewport;
    if (!force && (_isCovered(viewport) || _isRepeatRequest(viewport))) return;

    final requestId = ++_requestId;
    final requestBounds = viewport.expandBy(prefetchFactor);
    _lastRequestedViewport = viewport;
    _lastRequestedAt = _now();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getReportsInBounds(requestBounds, limit: limit);
      if (!mounted || requestId != _requestId) return;

      final data = response.data;
      if (response.success && data != null) {
        state = MapReportsState(
          reports: data.reports
              .where((r) => r.latitude != 0 || r.longitude != 0)
              .toList(),
          truncated: data.truncated,
          fetchedBounds: requestBounds,
          fetchedAt: _now(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Tải lại khung nhìn gần nhất, bỏ qua cache.
  Future<void> refresh() async {
    final viewport = _lastViewport;
    if (viewport == null) return;
    await loadForViewport(viewport, force: true);
  }

  bool _isFresh(DateTime? time) =>
      time != null && _now().difference(time) < freshness;

  /// Khung đã tải bao trọn [viewport] và không bị cắt bớt → không cần tải lại.
  bool _isCovered(MapBounds viewport) {
    final fetched = state.fetchedBounds;
    return fetched != null &&
        state.error == null &&
        !state.truncated &&
        _isFresh(state.fetchedAt) &&
        fetched.contains(viewport);
  }

  /// Cùng khung nhìn vừa yêu cầu (map idle lặp lại sau khi render) →
  /// kết quả sẽ giống hệt, kể cả khi truncated. Lỗi thì cho phép thử lại.
  bool _isRepeatRequest(MapBounds viewport) =>
      state.error == null &&
      viewport == _lastRequestedViewport &&
      _isFresh(_lastRequestedAt);
}

final mapReportsProvider =
    StateNotifierProvider.autoDispose<MapReportsNotifier, MapReportsState>(
  (ref) => MapReportsNotifier(reportService),
);
