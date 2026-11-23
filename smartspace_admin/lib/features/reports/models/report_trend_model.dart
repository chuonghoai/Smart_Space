class ReportTrendItem {
  final String label;
  final int count;
  final bool anomaly;
  final double? baselineAvg;

  const ReportTrendItem({
    required this.label,
    required this.count,
    this.anomaly = false,
    this.baselineAvg,
  });

  factory ReportTrendItem.fromJson(Map<String, dynamic> json) {
    return ReportTrendItem(
      label: json['label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      anomaly: json['anomaly'] as bool? ?? false,
      baselineAvg: (json['baselineAvg'] as num?)?.toDouble(),
    );
  }
}

class ReportTrendData {
  final List<ReportTrendItem> items;
  final double? baselineAvg14d;
  final int anomalyCount;
  final bool insufficientData;

  const ReportTrendData({
    this.items = const [],
    this.baselineAvg14d,
    this.anomalyCount = 0,
    this.insufficientData = false,
  });

  factory ReportTrendData.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? [])
        .map((e) => ReportTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReportTrendData(
      items: list,
      baselineAvg14d: (json['baselineAvg14d'] as num?)?.toDouble(),
      anomalyCount: (json['anomalyCount'] as num?)?.toInt() ?? 0,
      insufficientData: json['insufficientData'] as bool? ?? false,
    );
  }
}
