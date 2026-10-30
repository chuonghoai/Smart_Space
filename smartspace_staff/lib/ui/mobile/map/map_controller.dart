import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';

/// Chip trạng thái trên bản đồ Staff. Bản đồ chỉ tải việc đang xử lý nên mọi chip đều lọc tại máy:
/// - [all]: mọi việc đang xử lý (kể cả việc cần xử lý lại);
/// - [processing]: việc đang xử lý bình thường;
/// - [rehandling]: việc bị đánh giá chưa thoả đáng, cần xử lý lại.
enum StaffMapStatusFilter { all, processing, rehandling }

class MapState {
  final StaffMapStatusFilter statusFilter;
  final bool showDangerous;
  final bool showNormal;
  final ReportModel? selectedReport;

  const MapState({
    this.statusFilter = StaffMapStatusFilter.all,
    this.showDangerous = true,
    this.showNormal = true,
    this.selectedReport,
  });

  MapState copyWith({
    StaffMapStatusFilter? statusFilter,
    bool? showDangerous,
    bool? showNormal,
    ReportModel? selectedReport,
    bool clearSelection = false,
  }) {
    return MapState(
      statusFilter: statusFilter ?? this.statusFilter,
      showDangerous: showDangerous ?? this.showDangerous,
      showNormal: showNormal ?? this.showNormal,
      selectedReport: clearSelection
          ? null
          : (selectedReport ?? this.selectedReport),
    );
  }

  /// Hai tiêu chí độc lập, report phải qua cả hai:
  /// - trạng thái theo [statusFilter];
  /// - mức độ: nguy hiểm (high/critical) hoặc thông thường.
  List<ReportModel> getFilteredReports(List<ReportModel> reports) {
    return reports
        .where((r) => switch (statusFilter) {
              StaffMapStatusFilter.all => true,
              StaffMapStatusFilter.processing => !r.needsRehandling,
              StaffMapStatusFilter.rehandling => r.needsRehandling,
            })
        .where((r) => r.isDangerous ? showDangerous : showNormal)
        .toList();
  }
}

class MapController extends StateNotifier<MapState> {
  MapController() : super(const MapState());

  void setStatusFilter(StaffMapStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

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
