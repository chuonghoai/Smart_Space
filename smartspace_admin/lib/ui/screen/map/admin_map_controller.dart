import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
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
  static const Duration viewportDebounce = Duration(milliseconds: 400);

  final Ref _ref;
  Timer? _viewportDebounce;

  AdminMapController(this._ref) : super(const AdminMapState());

  /// Gọi khi camera dừng (mobile: map idle, web: moveend);
  /// chỉ tải sau khi người dùng ngừng kéo/zoom.
  void onViewportChanged(MapBounds bounds) {
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(viewportDebounce, () {
      _ref.read(mapReportsProvider.notifier).loadForViewport(bounds);
    });
  }

  /// Tải ngay khung [bounds], bỏ qua debounce và cache — dùng khi mở bản đồ focus vào một report,
  /// vì dữ liệu của lần mở trước (provider không autoDispose) có thể đã cũ.
  Future<void> loadNow(MapBounds bounds) {
    _viewportDebounce?.cancel();
    return _ref.read(mapReportsProvider.notifier).loadForViewport(bounds, force: true);
  }

  void refresh() {
    _viewportDebounce?.cancel();
    _ref.read(mapReportsProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    super.dispose();
  }

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
  (ref) => AdminMapController(ref),
);
