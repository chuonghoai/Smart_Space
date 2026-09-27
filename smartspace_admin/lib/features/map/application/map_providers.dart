import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final mapReportsProvider =
    AsyncNotifierProvider<MapReportsNotifier, List<MapReportModel>>(
      MapReportsNotifier.new,
    );

class MapReportsNotifier extends AsyncNotifier<List<MapReportModel>> {
  @override
  Future<List<MapReportModel>> build() => _fetch();

  Future<List<MapReportModel>> _fetch() async {
    final filter = ref.watch(mapFilterProvider);
    final res = await mapService.getMapReports(
      status: filter.status,
      severity: filter.severity,
      assigneeId: filter.assigneeId,
      from: filter.from,
      to: filter.to,
    );
    if (res.success && res.data != null) return res.data!;
    throw Exception(res.message);
  }

  /// Prepend a new report (from real-time WS) without re-fetching.
  void prependReport(MapReportModel report) {
    state.whenData((list) {
      state = AsyncData([report, ...list]);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// Staff list for filter dropdown

final mapStaffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final res = await reportRepository.getStaffs();
  if (res.success && res.data != null) return res.data!;
  return [];
});

