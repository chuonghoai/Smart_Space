import 'package:smartspace_client/features/reports/models/report_model.dart';

/// Một trang của `GET /reports/my-reports` (backend `PageResponse`, page 1-based).
class MyReportsPage {
  final List<ReportModel> items;
  final int totalPages;

  const MyReportsPage({required this.items, required this.totalPages});

  factory MyReportsPage.fromJson(Map<String, dynamic> json) => MyReportsPage(
        items: (json['content'] as List? ?? [])
            .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      );
}

/// Số liệu thẻ tổng hợp từ `GET /reports/my-reports/summary`, đếm trên toàn bộ phản ánh của user.
class MyReportsSummary {
  final int total;
  final int pending;
  final int processing;
  final int processed;
  final int rejected;
  final int rehandling;

  const MyReportsSummary({
    this.total = 0,
    this.pending = 0,
    this.processing = 0,
    this.processed = 0,
    this.rejected = 0,
    this.rehandling = 0,
  });

  factory MyReportsSummary.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return MyReportsSummary(
      total: read('total'),
      pending: read('pending'),
      processing: read('processing'),
      processed: read('processed'),
      rejected: read('rejected'),
      rehandling: read('rehandling'),
    );
  }
}
