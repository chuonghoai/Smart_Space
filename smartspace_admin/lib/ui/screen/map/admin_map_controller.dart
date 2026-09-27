import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';

class AdminMapState {
  final MapReportModel? selectedReport;
  final bool showHeatmap;
  final bool showStaffLayer;
  final bool isFilterExpanded;

  const AdminMapState({
    this.selectedReport,
    this.showHeatmap = false,
    this.showStaffLayer = false,
    this.isFilterExpanded = false,
  });

  AdminMapState copyWith({
    MapReportModel? selectedReport,
    bool? showHeatmap,
    bool? showStaffLayer,
    bool? isFilterExpanded,
    bool clearSelection = false,
  }) {
    return AdminMapState(
      selectedReport: clearSelection
          ? null
          : (selectedReport ?? this.selectedReport),
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showStaffLayer: showStaffLayer ?? this.showStaffLayer,
      isFilterExpanded: isFilterExpanded ?? this.isFilterExpanded,
    );
  }
}

class AdminMapController extends StateNotifier<AdminMapState> {
  AdminMapController() : super(const AdminMapState());

  void selectReport(MapReportModel report) =>
      state = state.copyWith(selectedReport: report);

  void clearSelection() => state = state.copyWith(clearSelection: true);

  void toggleHeatmap() =>
      state = state.copyWith(showHeatmap: !state.showHeatmap);

  void toggleStaffLayer() =>
      state = state.copyWith(showStaffLayer: !state.showStaffLayer);

  void toggleFilterPanel() =>
      state = state.copyWith(isFilterExpanded: !state.isFilterExpanded);
}

final adminMapControllerProvider =
    StateNotifierProvider<AdminMapController, AdminMapState>(
  (ref) => AdminMapController(),
);
