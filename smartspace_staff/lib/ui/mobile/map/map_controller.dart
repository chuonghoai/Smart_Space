import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';

class MapState {
  final bool showDangerous;
  final bool showNormal;
  final bool showRehandling;
  final ReportModel? selectedReport;

  const MapState({
    this.showDangerous = true,
    this.showNormal = true,
    this.showRehandling = true,
    this.selectedReport,
  });

  MapState copyWith({
    bool? showDangerous,
    bool? showNormal,
    bool? showRehandling,
    ReportModel? selectedReport,
    bool clearSelection = false,
  }) {
    return MapState(
      showDangerous: showDangerous ?? this.showDangerous,
      showNormal: showNormal ?? this.showNormal,
      showRehandling: showRehandling ?? this.showRehandling,
      selectedReport: clearSelection
          ? null
          : (selectedReport ?? this.selectedReport),
    );
  }

  /// Hai tiêu chí độc lập, report phải qua cả hai:
  /// - mức độ: nguy hiểm (high/critical) hoặc thông thường;
  /// - xử lý lại: tắt [showRehandling] → ẩn mọi việc cần xử lý lại, bất kể mức độ.
  List<ReportModel> getFilteredReports(List<ReportModel> reports) {
    return reports
        .where((r) => r.isDangerous ? showDangerous : showNormal)
        .where((r) => showRehandling || !r.needsRehandling)
        .toList();
  }
}

class MapController extends StateNotifier<MapState> {
  MapController() : super(const MapState());

  void toggleDangerous() {
    state = state.copyWith(showDangerous: !state.showDangerous);
  }

  void toggleNormal() {
    state = state.copyWith(showNormal: !state.showNormal);
  }

  void toggleRehandling() {
    state = state.copyWith(showRehandling: !state.showRehandling);
  }

  void selectReport(ReportModel report) {
    state = state.copyWith(selectedReport: report);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }
}

final mapControllerProvider =
    StateNotifierProvider.autoDispose<MapController, MapState>((ref) {
  return MapController();
});
