class ReportStatisticsModel {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> bySeverity;
  final int atRiskCount;
  final int bottleneckCount;
  final Map<String, int> p90MinutesBySeverity;
  final Map<String, bool> p90InsufficientSamples;

  const ReportStatisticsModel({
    required this.total,
    required this.byStatus,
    required this.bySeverity,
    this.atRiskCount = 0,
    this.bottleneckCount = 0,
    this.p90MinutesBySeverity = const {},
    this.p90InsufficientSamples = const {},
  });

  factory ReportStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ReportStatisticsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStatus: _parseIntMap(json['byStatus']),
      bySeverity: _parseIntMap(json['bySeverity']),
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
      bottleneckCount: (json['bottleneckCount'] as num?)?.toInt() ?? 0,
      p90MinutesBySeverity: _parseIntMap(json['p90MinutesBySeverity']),
      p90InsufficientSamples: _parseBoolMap(json['p90InsufficientSamples']),
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

  static Map<String, bool> _parseBoolMap(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(k.toString().toLowerCase(), v as bool? ?? false),
      );
    }
    return {};
  }

  int get pending => byStatus['pending'] ?? 0;
  int get processing => byStatus['processing'] ?? 0;
  int get resolved => byStatus['resolved'] ?? 0;
  int get rejected => byStatus['rejected'] ?? 0;
  int get rehandling => byStatus['rehandling'] ?? 0;
  int get overdue => byStatus['overdue'] ?? 0;
}
