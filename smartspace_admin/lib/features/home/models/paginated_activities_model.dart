import 'recent_activity_model.dart';

class PaginatedActivitiesModel {
  final List<RecentActivityModel> items;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;

  const PaginatedActivitiesModel({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
  });

  factory PaginatedActivitiesModel.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>? ?? [];
    return PaginatedActivitiesModel(
      items: list
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
