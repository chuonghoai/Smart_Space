import 'package:smartspace_client/features/reports/models/report_model.dart';

/// Kết quả `GET /reports/map`.
/// [truncated] = khung nhìn còn nhiều report hơn số được trả về.
class MapReportsResult {
  final List<ReportModel> reports;
  final bool truncated;

  const MapReportsResult({required this.reports, required this.truncated});

  factory MapReportsResult.fromJson(Map<String, dynamic> json) {
    final rawReports = json['reports'];
    return MapReportsResult(
      reports: rawReports is List
          ? rawReports
              .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      truncated: json['truncated'] as bool? ?? false,
    );
  }
}
