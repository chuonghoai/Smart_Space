import 'map_report_model.dart';

/// Kết quả `GET /admin/reports/map`.
/// [truncated] = còn nhiều report khớp bộ lọc hơn số được trả về.
class AdminMapReportsResult {
  final List<MapReportModel> reports;
  final bool truncated;

  const AdminMapReportsResult({required this.reports, required this.truncated});

  static const empty = AdminMapReportsResult(reports: [], truncated: false);

  factory AdminMapReportsResult.fromJson(Map<String, dynamic> json) {
    final rawReports = json['reports'];
    return AdminMapReportsResult(
      reports: rawReports is List
          ? rawReports
              .map((e) => MapReportModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      truncated: json['truncated'] as bool? ?? false,
    );
  }
}
