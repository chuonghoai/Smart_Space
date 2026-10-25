import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/features/reports/data/report_repository.dart';
import '../models/map_report_model.dart';
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

  const AdminMapReportsState({
    this.reports = const [],
    this.truncated = false,
    this.isLoading = false,
    this.error,
  });

  AdminMapReportsState copyWith({
    List<MapReportModel>? reports,
    bool? truncated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminMapReportsState(
      reports: reports ?? this.reports,
      truncated: truncated ?? this.truncated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final mapReportsProvider =
    NotifierProvider<MapReportsNotifier, AdminMapReportsState>(MapReportsNotifier.new);

/// Report trên bản đồ Admin, tải theo khung nhìn + bộ lọc.
/// Quy tắc khi nào tải lại nằm ở [ViewportLoadGate] (dùng chung với Client).
/// Giữ dữ liệu cũ trong lúc tải → bản đồ không bị dựng lại, camera giữ nguyên.
class MapReportsNotifier extends Notifier<AdminMapReportsState> {
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
    return const AdminMapReportsState();
  }

  Future<void> loadForViewport(MapBounds viewport, {bool force = false}) async {
    final request = _gate.begin(viewport, force: force);
    if (request == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final filter = ref.read(mapFilterProvider);

    try {
      final response = await _service.getMapReports(
        status: filter.status,
        severity: filter.severity,
        assigneeId: filter.assigneeId,
        from: filter.from,
        to: filter.to,
        bounds: request.bounds,
        limit: limit,
      );
      if (!_gate.isCurrent(request)) return;

      final data = response.data;
      if (response.success && data != null) {
        _gate.succeed(request, truncated: data.truncated);
        state = AdminMapReportsState(reports: data.reports, truncated: data.truncated);
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

// Staff list for filter dropdown

final mapStaffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final res = await reportRepository.getStaffs();
  if (res.success && res.data != null) return res.data!;
  return [];
});
