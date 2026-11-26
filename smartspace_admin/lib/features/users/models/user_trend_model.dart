class UserTrendItem {
  /// Ngày bắt đầu bucket: ngày (daily), thứ Hai (weekly), ngày 1 (monthly).
  final DateTime date;
  final int count;

  const UserTrendItem({required this.date, required this.count});

  factory UserTrendItem.fromJson(Map<String, dynamic> json) {
    return UserTrendItem(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime(1970),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
