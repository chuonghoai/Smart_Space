class ReportTrendItem {
  final String label;
  final int count;

  const ReportTrendItem({required this.label, required this.count});

  factory ReportTrendItem.fromJson(Map<String, dynamic> json) {
    return ReportTrendItem(
      label: json['label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
