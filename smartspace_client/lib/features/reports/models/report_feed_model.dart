import 'package:smartspace_client/features/reports/models/report_detail_model.dart';

/// Public feed item: detail fields + reporter identity (null when anonymous).
class ReportFeedItem {
  final ReportDetailModel report;
  final String? reporterName;
  final String? reporterAvatarUrl;

  const ReportFeedItem({required this.report, this.reporterName, this.reporterAvatarUrl});

  factory ReportFeedItem.fromJson(Map<String, dynamic> json) => ReportFeedItem(
        report: ReportDetailModel.fromJson(json),
        reporterName: json['user_name'] as String?,
        reporterAvatarUrl: json['user_avatar_url'] as String?,
      );
}

class ReportFeedPage {
  final List<ReportFeedItem> items;
  final int totalPages;

  const ReportFeedPage({required this.items, required this.totalPages});

  factory ReportFeedPage.fromJson(Map<String, dynamic> json) => ReportFeedPage(
        items: (json['content'] as List? ?? [])
            .map((e) => ReportFeedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      );
}
