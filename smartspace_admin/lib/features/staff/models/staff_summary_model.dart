class StaffSummaryModel {
  final int total;
  final int active;
  final int blocked;
  final int totalProcessing;

  const StaffSummaryModel({
    required this.total,
    required this.active,
    required this.blocked,
    required this.totalProcessing,
  });

  factory StaffSummaryModel.fromJson(Map<String, dynamic> json) {
    return StaffSummaryModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      blocked: (json['blocked'] as num?)?.toInt() ?? 0,
      totalProcessing: (json['totalProcessing'] as num?)?.toInt() ?? 0,
    );
  }
}
