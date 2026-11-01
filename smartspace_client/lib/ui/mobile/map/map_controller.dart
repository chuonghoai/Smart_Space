import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/map_reports_provider.dart';

/// UI State cho Map Screen
class MapState {
  final bool showDangerous;
  final bool showNormal;
  final ReportModel? selectedReport;

  const MapState({
    this.showDangerous = true,
    this.showNormal = true,
    this.selectedReport,
  });

  MapState copyWith({
    bool? showDangerous,
    bool? showNormal,
    ReportModel? selectedReport,
    bool clearSelection = false,
  }) {
    return MapState(
      showDangerous: showDangerous ?? this.showDangerous,
      showNormal: showNormal ?? this.showNormal,
      selectedReport: clearSelection
          ? null
          : (selectedReport ?? this.selectedReport),
    );
  }

  /// Lọc report theo 2 nhóm không chồng nhau: nguy hiểm (high/critical) và thông thường.
  List<ReportModel> getFilteredReports(List<ReportModel> reports) {
    return reports
        .where((r) => r.isDangerous ? showDangerous : showNormal)
        .toList();
  }
}

/// UI Controller — StateNotifier quản lý trạng thái UI của Map
class MapController extends StateNotifier<MapState> {
  static const Duration viewportDebounce = Duration(milliseconds: 400);

  final Ref _ref;
  Timer? _viewportDebounce;

  MapController(this._ref) : super(const MapState());

  void toggleDangerous() {
    state = state.copyWith(showDangerous: !state.showDangerous);
  }

  void toggleNormal() {
    state = state.copyWith(showNormal: !state.showNormal);
  }

  void selectReport(ReportModel report) {
    state = state.copyWith(selectedReport: report);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Gọi khi camera dừng; chỉ tải sau khi người dùng ngừng kéo/zoom.
  void onViewportChanged(MapBounds bounds) {
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(viewportDebounce, () {
      _ref.read(mapReportsProvider.notifier).loadForViewport(bounds);
    });
  }

  void refresh() {
    _viewportDebounce?.cancel();
    _ref.read(mapReportsProvider.notifier).refresh();
  }

  void setFilter(MapReportFilter filter) {
    _viewportDebounce?.cancel();
    _ref.read(mapReportsProvider.notifier).setFilter(filter);
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    super.dispose();
  }
}

final mapControllerProvider =
    StateNotifierProvider.autoDispose<MapController, MapState>((ref) {
  return MapController(ref);
});
