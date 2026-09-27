class ReportStatisticsModel {
  final int total;
  final Map<String, int> byStatus;

  ReportStatisticsModel({
    required this.total,
    required this.byStatus,
  });

  factory ReportStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ReportStatisticsModel(
      total: json['total'] as int? ?? 0,
      byStatus: ((json['by_status'] ?? json['byStatus']) as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }

  int get pending => byStatus['pending'] ?? 0;
  int get processing => byStatus['processing'] ?? 0;
  int get resolved => byStatus['resolved'] ?? 0;
  int get rejected => byStatus['rejected'] ?? 0;
}
