import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';

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

class MapController extends StateNotifier<MapState> {
  MapController() : super(const MapState());

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
}

final mapControllerProvider =
    StateNotifierProvider.autoDispose<MapController, MapState>((ref) {
  return MapController();
});
