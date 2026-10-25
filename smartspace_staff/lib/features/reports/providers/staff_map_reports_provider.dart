import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';

/// Việc đang xử lý của staff trên bản đồ.
/// [truncated] = có thể còn việc khác vì backend chỉ trả tối đa [StaffMapReportsNotifier.limit].
class StaffMapReports {
  final List<ReportModel> reports;
  final bool truncated;

  const StaffMapReports({required this.reports, required this.truncated});
}

/// Tải toàn bộ việc đang xử lý (gồm việc cần xử lý lại) một lần, độc lập với tab lọc của Home.
/// Số việc của một staff có giới hạn nên không cần tải theo khung nhìn như Client/Admin.
class StaffMapReportsNotifier extends AutoDisposeAsyncNotifier<StaffMapReports> {
  /// Giới hạn trên của `/reports/staff/assigned`.
  static const int limit = 100;

  final ReportService _service;

  StaffMapReportsNotifier({ReportService? service}) : _service = service ?? reportService;

  @override
  Future<StaffMapReports> build() => _fetch();

  Future<StaffMapReports> _fetch() async {
    final response = await _service.getStaffAssignedReports(status: 'processing', limit: limit);
    final data = response.data;
    if (!response.success || data == null) throw Exception(response.message);

    return StaffMapReports(
      reports: data.where((r) => r.latitude != 0 || r.longitude != 0).toList(),
      truncated: data.length >= limit,
    );
  }

  /// Tải lại nhưng giữ dữ liệu cũ (kể cả khi lỗi) → bản đồ không bị trống/dựng lại.
  Future<void> refresh() async {
    state = const AsyncLoading<StaffMapReports>().copyWithPrevious(state);
    final result = await AsyncValue.guard(_fetch);
    state = result.copyWithPrevious(state);
  }
}

final staffMapReportsProvider =
    AsyncNotifierProvider.autoDispose<StaffMapReportsNotifier, StaffMapReports>(
  StaffMapReportsNotifier.new,
);
