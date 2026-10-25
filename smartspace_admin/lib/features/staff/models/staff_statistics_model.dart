import 'package:smartspace_admin/features/staff/models/staff_model.dart';

class StaffStatisticsModel {
  final int totalStaff;
  final int activeStaff;
  final int blockedStaff;
  final int processingReports;
  final int resolved;
  final int resolvedPrevious;

  /// Null khi chưa có báo cáo đủ dữ liệu để tính (thiếu thời điểm phân công).
  final int? avgResolutionMinutes;
  final int? avgResolutionMinutesPrevious;
  final List<StaffWorkloadItem> workload;

  const StaffStatisticsModel({
    required this.totalStaff,
    required this.activeStaff,
    required this.blockedStaff,
    required this.processingReports,
    required this.resolved,
    required this.resolvedPrevious,
    this.avgResolutionMinutes,
    this.avgResolutionMinutesPrevious,
    required this.workload,
  });

  factory StaffStatisticsModel.fromJson(Map<String, dynamic> json) {
    final workloadList = json['workload'] as List<dynamic>? ?? [];
    return StaffStatisticsModel(
      totalStaff: (json['totalStaff'] as num?)?.toInt() ?? 0,
      activeStaff: (json['activeStaff'] as num?)?.toInt() ?? 0,
      blockedStaff: (json['blockedStaff'] as num?)?.toInt() ?? 0,
      processingReports: (json['processingReports'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      resolvedPrevious: (json['resolvedPrevious'] as num?)?.toInt() ?? 0,
      avgResolutionMinutes: (json['avgResolutionMinutes'] as num?)?.toInt(),
      avgResolutionMinutesPrevious:
          (json['avgResolutionMinutesPrevious'] as num?)?.toInt(),
      workload: workloadList
          .map((e) => StaffWorkloadItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Số báo cáo đang xử lý trung bình trên mỗi nhân viên hoạt động. Null khi không có ai.
  double? get processingPerActiveStaff =>
      activeStaff == 0 ? null : processingReports / activeStaff;
}

class StaffWorkloadItem {
  /// `processingCount` = số báo cáo đang xử lý.
  final StaffModel staff;

  /// Số báo cáo đã xử lý trong 30 ngày.
  final int resolvedCount;

  const StaffWorkloadItem({required this.staff, required this.resolvedCount});

  factory StaffWorkloadItem.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadItem(
      staff: StaffModel.fromJson(
        json['staff'] as Map<String, dynamic>? ?? const {},
      ),
      resolvedCount: (json['resolvedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
