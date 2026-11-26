import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';

/// Một trang SOS từ /admin/sos (PageResponse 1-based của backend).
class SosAlertPage {
  final List<SosAlertModel> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const SosAlertPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory SosAlertPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return SosAlertPage(
      items: content is List
          ? content.map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((e) => e.toJson()).toList(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalElements': totalElements,
    };
  }
}
