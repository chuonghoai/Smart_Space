class StaffChartModel {
  final int totalStaff;
  final int activeStaff;
  final int blockedStaff;
  final List<WorkloadItem> topWorkload;

  const StaffChartModel({
    required this.totalStaff,
    required this.activeStaff,
    required this.blockedStaff,
    required this.topWorkload,
  });

  factory StaffChartModel.fromJson(Map<String, dynamic> json) {
    final workloadList = json['topWorkload'] as List<dynamic>? ?? [];
    return StaffChartModel(
      totalStaff: (json['totalStaff'] as num?)?.toInt() ?? 0,
      activeStaff: (json['activeStaff'] as num?)?.toInt() ?? 0,
      blockedStaff: (json['blockedStaff'] as num?)?.toInt() ?? 0,
      topWorkload: workloadList
          .map((e) => WorkloadItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkloadItem {
  final String staffId;
  final String staffName;
  final int processingCount;

  const WorkloadItem({
    required this.staffId,
    required this.staffName,
    required this.processingCount,
  });

  factory WorkloadItem.fromJson(Map<String, dynamic> json) {
    return WorkloadItem(
      staffId: json['staffId'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
