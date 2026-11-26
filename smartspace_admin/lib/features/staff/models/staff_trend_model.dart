class StaffTrendItem {
  /// Ngày bắt đầu bucket: ngày (daily), thứ Hai (weekly), ngày 1 (monthly).
  final DateTime date;

  /// Số báo cáo được phân công trong bucket.
  final int assigned;

  /// Số báo cáo đã xử lý xong trong bucket.
  final int resolved;

  const StaffTrendItem({
    required this.date,
    required this.assigned,
    required this.resolved,
  });

  factory StaffTrendItem.fromJson(Map<String, dynamic> json) {
    return StaffTrendItem(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime(1970),
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
    );
  }
}
