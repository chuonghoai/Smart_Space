import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_providers.dart';

/// UI State cho Map Screen
class MapState {
  final bool showDangerous;
  final bool showRecent;
  final ReportModel? selectedReport;

  const MapState({
    this.showDangerous = true,
    this.showRecent = true,
    this.selectedReport,
  });

  MapState copyWith({
    bool? showDangerous,
    bool? showRecent,
    ReportModel? selectedReport,
    bool clearSelection = false,
  }) {
    return MapState(
      showDangerous: showDangerous ?? this.showDangerous,
      showRecent: showRecent ?? this.showRecent,
      selectedReport: clearSelection
          ? null
          : (selectedReport ?? this.selectedReport),
    );
  }

  /// Lấy danh sách reports đã filter từ ReportsState
  List<ReportModel> getFilteredReports(ReportsState reportsState) {
    final List<ReportModel> result = [];
    if (showDangerous) result.addAll(reportsState.dangerousReports);
    if (showRecent) result.addAll(reportsState.recentReports);

    // Loại bỏ duplicate (report có thể nằm trong cả 2 danh sách)
    final seen = <String>{};
    return result.where((r) => seen.add(r.id)).toList();
  }
}

/// UI Controller — StateNotifier quản lý trạng thái UI của Map
class MapController extends StateNotifier<MapState> {
  MapController() : super(const MapState());

  void toggleDangerous() {
    state = state.copyWith(showDangerous: !state.showDangerous);
  }

  void toggleRecent() {
    state = state.copyWith(showRecent: !state.showRecent);
  }

  void selectReport(ReportModel report) {
    state = state.copyWith(selectedReport: report);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final mapControllerProvider = StateNotifierProvider<MapController, MapState>((
  ref,
) {
  return MapController();
});
