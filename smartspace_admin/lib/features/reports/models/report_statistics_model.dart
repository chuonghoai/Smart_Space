class ReportStatisticsModel {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> bySeverity;

  const ReportStatisticsModel({
    required this.total,
    required this.byStatus,
    required this.bySeverity,
  });

  factory ReportStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ReportStatisticsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStatus: _parseIntMap(json['byStatus']),
      bySeverity: _parseIntMap(json['bySeverity']),
    );
  }

  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(k.toString().toLowerCase(), (v as num?)?.toInt() ?? 0),
      );
    }
    return {};
  }

  int get pending => byStatus['pending'] ?? 0;
  int get processing => byStatus['processing'] ?? 0;
  int get resolved => byStatus['resolved'] ?? 0;
  int get rejected => byStatus['rejected'] ?? 0;
}
