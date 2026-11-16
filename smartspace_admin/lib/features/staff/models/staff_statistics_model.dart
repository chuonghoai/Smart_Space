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
  final bool anyStaffMissedDeadline;
  final int overdueReports;
  final int completedOnTime;
  final int completedLate;
  final double? onTimeRate;
  final List<StaffDeadlinePerformanceItem> deadlinePerformance;
  final int selectedYear;
  final int selectedMonth;
  final List<AvailableMonthItem> availableMonths;

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
    this.anyStaffMissedDeadline = false,
    this.overdueReports = 0,
    this.completedOnTime = 0,
    this.completedLate = 0,
    this.onTimeRate,
    this.deadlinePerformance = const [],
    this.selectedYear = 0,
    this.selectedMonth = 0,
    this.availableMonths = const [],
  });

  factory StaffStatisticsModel.fromJson(Map<String, dynamic> json) {
    final workloadList = json['workload'] as List<dynamic>? ?? [];
    final performanceList = json['deadlinePerformance'] as List<dynamic>? ?? [];
    final availableMonthsList = json['availableMonths'] as List<dynamic>? ?? [];
    final now = DateTime.now();
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
      anyStaffMissedDeadline: json['anyStaffMissedDeadline'] as bool? ?? false,
      overdueReports: (json['overdueReports'] as num?)?.toInt() ?? 0,
      completedOnTime: (json['completedOnTime'] as num?)?.toInt() ?? 0,
      completedLate: (json['completedLate'] as num?)?.toInt() ?? 0,
      onTimeRate: (json['onTimeRate'] as num?)?.toDouble(),
      deadlinePerformance: performanceList
          .map(
            (e) => StaffDeadlinePerformanceItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      selectedYear: (json['selectedYear'] as num?)?.toInt() ?? now.year,
      selectedMonth: (json['selectedMonth'] as num?)?.toInt() ?? now.month,
      availableMonths: availableMonthsList
          .map((e) => AvailableMonthItem.fromJson(e as Map<String, dynamic>))
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

class StaffDeadlinePerformanceItem {
  final StaffModel staff;
  final int overdueCount;
  final int completedLateCount;
  final int completedOnTimeCount;
  final bool hasMissedDeadline;
  final int processingCount;
  final int resolvedCount;
  final int rehandlingCount;
  final int totalTasks;
  final double? efficiencyRate;

  const StaffDeadlinePerformanceItem({
    required this.staff,
    required this.overdueCount,
    required this.completedLateCount,
    required this.completedOnTimeCount,
    required this.hasMissedDeadline,
    this.processingCount = 0,
    this.resolvedCount = 0,
    this.rehandlingCount = 0,
    this.totalTasks = 0,
    this.efficiencyRate,
  });

  int get totalLateCount => overdueCount + completedLateCount;

  factory StaffDeadlinePerformanceItem.fromJson(Map<String, dynamic> json) {
    return StaffDeadlinePerformanceItem(
      staff: StaffModel.fromJson(
        json['staff'] as Map<String, dynamic>? ?? const {},
      ),
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      completedLateCount: (json['completedLateCount'] as num?)?.toInt() ?? 0,
      completedOnTimeCount:
          (json['completedOnTimeCount'] as num?)?.toInt() ?? 0,
      hasMissedDeadline: json['hasMissedDeadline'] as bool? ?? false,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      resolvedCount: (json['resolvedCount'] as num?)?.toInt() ?? 0,
      rehandlingCount: (json['rehandlingCount'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      efficiencyRate: (json['efficiencyRate'] as num?)?.toDouble(),
    );
  }
}

class AvailableMonthItem {
  final int year;
  final int month;
  final String label;

  const AvailableMonthItem({
    required this.year,
    required this.month,
    required this.label,
  });

  factory AvailableMonthItem.fromJson(Map<String, dynamic> json) {
    final year = (json['year'] as num?)?.toInt() ?? DateTime.now().year;
    final month = (json['month'] as num?)?.toInt() ?? DateTime.now().month;
    final fallbackLabel = '${month.toString().padLeft(2, '0')}/$year';
    return AvailableMonthItem(
      year: year,
      month: month,
      label: json['label']?.toString() ?? fallbackLabel,
    );
  }
}
