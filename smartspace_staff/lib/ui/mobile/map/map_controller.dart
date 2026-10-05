import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';

class MapState {
  final bool showDangerous;
  final bool showRecent; // Hoặc showAssigned, nhưng ta giữ tên để tương thích với map_controls
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

  List<ReportModel> getFilteredReports(HomeState homeState) {
    final List<ReportModel> result = [];
    
    // For staff, we filter from assignedReports
    for (final report in homeState.assignedReports) {
      // Logic phân loại dựa trên severity (nếu cần) hoặc trả về tất cả
      // Giả sử 'showDangerous' là các report severity = critical/high
      final isDangerous = report.severity == ReportSeverity.critical || report.severity == ReportSeverity.high;
      
      if (isDangerous && showDangerous) {
        result.add(report);
      } else if (!isDangerous && showRecent) {
        result.add(report);
      }
    }

    // Loại bỏ duplicate
    final seen = <String>{};
    return result.where((r) => seen.add(r.id)).toList();
  }
}

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
