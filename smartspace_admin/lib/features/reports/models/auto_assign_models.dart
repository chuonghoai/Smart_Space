import 'package:smartspace_admin/features/reports/models/staff_model.dart';

class StaffCandidateScoreModel {
  final int rank;
  final String staffId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? positionId;
  final String? positionName;
  final double? baseLatitude;
  final double? baseLongitude;
  final String? baseAddress;
  final double distanceKm;
  final int monthlyWorkload;
  final int activeProcessingCount;
  final double onTimeRate30d;
  final double distanceScore;
  final double monthlyWorkloadScore;
  final double activeLoadScore;
  final double onTimeRateScore;
  final double finalScore;
  final double weightDistance;
  final double weightMonthlyWorkload;
  final double weightActiveLoad;
  final double weightOnTimeRate;

  const StaffCandidateScoreModel({
    required this.rank,
    required this.staffId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.positionId,
    this.positionName,
    this.baseLatitude,
    this.baseLongitude,
    this.baseAddress,
    required this.distanceKm,
    required this.monthlyWorkload,
    required this.activeProcessingCount,
    required this.onTimeRate30d,
    required this.distanceScore,
    required this.monthlyWorkloadScore,
    required this.activeLoadScore,
    required this.onTimeRateScore,
    required this.finalScore,
    this.weightDistance = 0.45,
    this.weightMonthlyWorkload = 0.35,
    this.weightActiveLoad = 0.15,
    this.weightOnTimeRate = 0.05,
  });

  factory StaffCandidateScoreModel.fromJson(Map<String, dynamic> json) {
    return StaffCandidateScoreModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      staffId: (json['staff_id'] ?? json['staffId'])?.toString() ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      positionId: (json['position_id'] ?? json['positionId']) as String?,
      positionName: (json['position_name'] ?? json['positionName']) as String?,
      baseLatitude:
          ((json['base_latitude'] ?? json['baseLatitude']) as num?)?.toDouble(),
      baseLongitude: ((json['base_longitude'] ?? json['baseLongitude']) as num?)
          ?.toDouble(),
      baseAddress: (json['base_address'] ?? json['baseAddress']) as String?,
      distanceKm:
          ((json['distance_km'] ?? json['distanceKm']) as num?)?.toDouble() ??
              0.0,
      monthlyWorkload:
          ((json['monthly_workload'] ?? json['monthlyWorkload']) as num?)
                  ?.toInt() ??
              0,
      activeProcessingCount:
          ((json['active_processing_count'] ?? json['activeProcessingCount'])
                      as num?)
                  ?.toInt() ??
              0,
      onTimeRate30d:
          ((json['on_time_rate_30d'] ?? json['onTimeRate30d']) as num?)
                  ?.toDouble() ??
              85.0,
      distanceScore:
          ((json['distance_score'] ?? json['distanceScore']) as num?)
                  ?.toDouble() ??
              0.0,
      monthlyWorkloadScore: ((json['monthly_workload_score'] ??
                  json['monthlyWorkloadScore']) as num?)
              ?.toDouble() ??
          0.0,
      activeLoadScore:
          ((json['active_load_score'] ?? json['activeLoadScore']) as num?)
                  ?.toDouble() ??
              0.0,
      onTimeRateScore:
          ((json['on_time_rate_score'] ?? json['onTimeRateScore']) as num?)
                  ?.toDouble() ??
              0.0,
      finalScore:
          ((json['final_score'] ?? json['finalScore']) as num?)?.toDouble() ??
              0.0,
      weightDistance:
          ((json['weight_distance'] ?? json['weightDistance']) as num?)
                  ?.toDouble() ??
              0.45,
      weightMonthlyWorkload: ((json['weight_monthly_workload'] ??
                  json['weightMonthlyWorkload']) as num?)
              ?.toDouble() ??
          0.35,
      weightActiveLoad:
          ((json['weight_active_load'] ?? json['weightActiveLoad']) as num?)
                  ?.toDouble() ??
              0.15,
      weightOnTimeRate:
          ((json['weight_on_time_rate'] ?? json['weightOnTimeRate']) as num?)
                  ?.toDouble() ??
              0.05,
    );
  }

  StaffModel toStaffModel() {
    return StaffModel(
      id: staffId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      positionId: positionId,
      positionName: positionName,
      processingCount: activeProcessingCount,
    );
  }
}

class AutoAssignRecommendationModel {
  final String reportId;
  final String? categoryId;
  final String? categoryCode;
  final String? categoryNameVi;
  final String? categoryNameEn;
  final String currentMode;
  final double maxRadiusKm;
  final int maxConcurrentTasks;
  final int totalEligibleCandidates;
  final String? fallbackReason;
  final String? fallbackMessage;
  final List<StaffCandidateScoreModel> candidates;

  const AutoAssignRecommendationModel({
    required this.reportId,
    this.categoryId,
    this.categoryCode,
    this.categoryNameVi,
    this.categoryNameEn,
    required this.currentMode,
    required this.maxRadiusKm,
    required this.maxConcurrentTasks,
    required this.totalEligibleCandidates,
    this.fallbackReason,
    this.fallbackMessage,
    this.candidates = const [],
  });

  factory AutoAssignRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['candidates'];
    final List<StaffCandidateScoreModel> parsed = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(StaffCandidateScoreModel.fromJson)
            .toList()
        : const [];

    return AutoAssignRecommendationModel(
      reportId: (json['report_id'] ?? json['reportId'])?.toString() ?? '',
      categoryId: (json['category_id'] ?? json['categoryId'])?.toString(),
      categoryCode: (json['category_code'] ?? json['categoryCode']) as String?,
      categoryNameVi:
          (json['category_name_vi'] ?? json['categoryNameVi']) as String?,
      categoryNameEn:
          (json['category_name_en'] ?? json['categoryNameEn']) as String?,
      currentMode:
          (json['current_mode'] ?? json['currentMode']) as String? ?? 'AUTO',
      maxRadiusKm:
          ((json['max_radius_km'] ?? json['maxRadiusKm']) as num?)?.toDouble() ??
              15.0,
      maxConcurrentTasks:
          ((json['max_concurrent_tasks'] ?? json['maxConcurrentTasks']) as num?)
                  ?.toInt() ??
              10,
      totalEligibleCandidates: ((json['total_eligible_candidates'] ??
                  json['totalEligibleCandidates']) as num?)
              ?.toInt() ??
          parsed.length,
      fallbackReason:
          (json['fallback_reason'] ?? json['fallbackReason']) as String?,
      fallbackMessage:
          (json['fallback_message'] ?? json['fallbackMessage']) as String?,
      candidates: parsed,
    );
  }
}

class AssignmentDecisionSummaryModel {
  final String id;
  final String? modeAtDecision;
  final String? source;
  final String? outcome;
  final String? selectedStaffId;
  final String? selectedStaffName;
  final String? selectedStaffEmail;
  final String? selectedStaffPositionName;
  final double? finalScore;
  final double? distanceKm;
  final double? distanceScore;
  final int? monthlyWorkload;
  final double? monthlyWorkloadScore;
  final int? activeProcessingCount;
  final double? activeLoadScore;
  final double? onTimeRate30d;
  final double? onTimeRateScore;
  final int? eligibleCandidateCount;
  final String? fallbackReason;
  final String? fallbackMessage;
  final String? overriddenByAdminId;
  final String? overriddenToStaffId;
  final String? overriddenToStaffName;
  final DateTime? overriddenAt;
  final DateTime? createdAt;
  final List<StaffCandidateScoreModel> candidatesSnapshot;

  const AssignmentDecisionSummaryModel({
    required this.id,
    this.modeAtDecision,
    this.source,
    this.outcome,
    this.selectedStaffId,
    this.selectedStaffName,
    this.selectedStaffEmail,
    this.selectedStaffPositionName,
    this.finalScore,
    this.distanceKm,
    this.distanceScore,
    this.monthlyWorkload,
    this.monthlyWorkloadScore,
    this.activeProcessingCount,
    this.activeLoadScore,
    this.onTimeRate30d,
    this.onTimeRateScore,
    this.eligibleCandidateCount,
    this.fallbackReason,
    this.fallbackMessage,
    this.overriddenByAdminId,
    this.overriddenToStaffId,
    this.overriddenToStaffName,
    this.overriddenAt,
    this.createdAt,
    this.candidatesSnapshot = const [],
  });

  factory AssignmentDecisionSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawSnapshot =
        json['candidates_snapshot'] ?? json['candidatesSnapshot'];
    final List<StaffCandidateScoreModel> parsedSnapshot = rawSnapshot is List
        ? rawSnapshot
            .whereType<Map<String, dynamic>>()
            .map(StaffCandidateScoreModel.fromJson)
            .toList()
        : const [];

    return AssignmentDecisionSummaryModel(
      id: json['id']?.toString() ?? '',
      modeAtDecision:
          (json['mode_at_decision'] ?? json['modeAtDecision']) as String?,
      source: json['source'] as String?,
      outcome: json['outcome'] as String?,
      selectedStaffId:
          (json['selected_staff_id'] ?? json['selectedStaffId'])?.toString(),
      selectedStaffName:
          (json['selected_staff_name'] ?? json['selectedStaffName']) as String?,
      selectedStaffEmail: (json['selected_staff_email'] ??
          json['selectedStaffEmail']) as String?,
      selectedStaffPositionName: (json['selected_staff_position_name'] ??
          json['selectedStaffPositionName']) as String?,
      finalScore:
          ((json['final_score'] ?? json['finalScore']) as num?)?.toDouble(),
      distanceKm:
          ((json['distance_km'] ?? json['distanceKm']) as num?)?.toDouble(),
      distanceScore:
          ((json['distance_score'] ?? json['distanceScore']) as num?)
              ?.toDouble(),
      monthlyWorkload:
          ((json['monthly_workload'] ?? json['monthlyWorkload']) as num?)
              ?.toInt(),
      monthlyWorkloadScore: ((json['monthly_workload_score'] ??
              json['monthlyWorkloadScore']) as num?)
          ?.toDouble(),
      activeProcessingCount: ((json['active_processing_count'] ??
              json['activeProcessingCount']) as num?)
          ?.toInt(),
      activeLoadScore:
          ((json['active_load_score'] ?? json['activeLoadScore']) as num?)
              ?.toDouble(),
      onTimeRate30d:
          ((json['on_time_rate_30d'] ?? json['onTimeRate30d']) as num?)
              ?.toDouble(),
      onTimeRateScore:
          ((json['on_time_rate_score'] ?? json['onTimeRateScore']) as num?)
              ?.toDouble(),
      eligibleCandidateCount: ((json['eligible_candidate_count'] ??
              json['eligibleCandidateCount']) as num?)
          ?.toInt(),
      fallbackReason:
          (json['fallback_reason'] ?? json['fallbackReason']) as String?,
      fallbackMessage:
          (json['fallback_message'] ?? json['fallbackMessage']) as String?,
      overriddenByAdminId: (json['overridden_by_admin_id'] ??
          json['overriddenByAdminId'])?.toString(),
      overriddenToStaffId: (json['overridden_to_staff_id'] ??
          json['overriddenToStaffId'])?.toString(),
      overriddenToStaffName: (json['overridden_to_staff_name'] ??
          json['overriddenToStaffName']) as String?,
      overriddenAt: (json['overridden_at'] ?? json['overriddenAt']) != null
          ? DateTime.tryParse(
              (json['overridden_at'] ?? json['overriddenAt']).toString())
          : null,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse(
              (json['created_at'] ?? json['createdAt']).toString())
          : null,
      candidatesSnapshot: parsedSnapshot,
    );
  }
}
