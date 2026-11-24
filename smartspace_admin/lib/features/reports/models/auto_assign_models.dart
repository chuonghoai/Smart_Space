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

class AutoAssignConfigModel {
  final String? id;
  final String mode;
  final double distanceWeight;
  final double monthlyWorkloadWeight;
  final double activeLoadWeight;
  final double onTimeRateWeight;
  final double maxRadiusKm;
  final int maxConcurrentTasks;
  final int targetMonthlyTasks;
  final String? updatedByAdminId;
  final DateTime? updatedAt;

  const AutoAssignConfigModel({
    this.id,
    this.mode = 'ASSIST',
    this.distanceWeight = 0.35,
    this.monthlyWorkloadWeight = 0.30,
    this.activeLoadWeight = 0.20,
    this.onTimeRateWeight = 0.15,
    this.maxRadiusKm = 15.0,
    this.maxConcurrentTasks = 10,
    this.targetMonthlyTasks = 20,
    this.updatedByAdminId,
    this.updatedAt,
  });

  int get distancePercent =>
      (distanceWeight <= 1.0 ? distanceWeight * 100 : distanceWeight).round();
  int get monthlyWorkloadPercent =>
      (monthlyWorkloadWeight <= 1.0
              ? monthlyWorkloadWeight * 100
              : monthlyWorkloadWeight)
          .round();
  int get activeLoadPercent =>
      (activeLoadWeight <= 1.0 ? activeLoadWeight * 100 : activeLoadWeight)
          .round();
  int get onTimeRatePercent =>
      (onTimeRateWeight <= 1.0 ? onTimeRateWeight * 100 : onTimeRateWeight)
          .round();

  AutoAssignConfigModel copyWith({
    String? id,
    String? mode,
    double? distanceWeight,
    double? monthlyWorkloadWeight,
    double? activeLoadWeight,
    double? onTimeRateWeight,
    double? maxRadiusKm,
    int? maxConcurrentTasks,
    int? targetMonthlyTasks,
    String? updatedByAdminId,
    DateTime? updatedAt,
  }) {
    return AutoAssignConfigModel(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      distanceWeight: distanceWeight ?? this.distanceWeight,
      monthlyWorkloadWeight:
          monthlyWorkloadWeight ?? this.monthlyWorkloadWeight,
      activeLoadWeight: activeLoadWeight ?? this.activeLoadWeight,
      onTimeRateWeight: onTimeRateWeight ?? this.onTimeRateWeight,
      maxRadiusKm: maxRadiusKm ?? this.maxRadiusKm,
      maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
      targetMonthlyTasks: targetMonthlyTasks ?? this.targetMonthlyTasks,
      updatedByAdminId: updatedByAdminId ?? this.updatedByAdminId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AutoAssignConfigModel.fromJson(Map<String, dynamic> json) {
    return AutoAssignConfigModel(
      id: json['id']?.toString(),
      mode: (json['mode'] as String?)?.toUpperCase() ?? 'ASSIST',
      distanceWeight:
          ((json['distance_weight'] ?? json['distanceWeight']) as num?)
                  ?.toDouble() ??
              0.35,
      monthlyWorkloadWeight: ((json['monthly_workload_weight'] ??
                  json['monthlyWorkloadWeight']) as num?)
              ?.toDouble() ??
          0.30,
      activeLoadWeight:
          ((json['active_load_weight'] ?? json['activeLoadWeight']) as num?)
                  ?.toDouble() ??
              0.20,
      onTimeRateWeight:
          ((json['on_time_rate_weight'] ?? json['onTimeRateWeight']) as num?)
                  ?.toDouble() ??
              0.15,
      maxRadiusKm:
          ((json['max_radius_km'] ?? json['maxRadiusKm']) as num?)?.toDouble() ??
              15.0,
      maxConcurrentTasks:
          ((json['max_concurrent_tasks'] ?? json['maxConcurrentTasks']) as num?)
                  ?.toInt() ??
              10,
      targetMonthlyTasks:
          ((json['target_monthly_tasks'] ?? json['targetMonthlyTasks']) as num?)
                  ?.toInt() ??
              20,
      updatedByAdminId:
          (json['updated_by_admin_id'] ?? json['updatedByAdminId'])?.toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.tryParse(
              (json['updated_at'] ?? json['updatedAt']).toString())
          : null,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'mode': mode,
      'distanceWeight': distancePercent,
      'monthlyWorkloadWeight': monthlyWorkloadPercent,
      'activeLoadWeight': activeLoadPercent,
      'onTimeRateWeight': onTimeRatePercent,
      'maxRadiusKm': maxRadiusKm,
      'maxConcurrentTasks': maxConcurrentTasks,
      'targetMonthlyTasks': targetMonthlyTasks,
    };
  }
}

class AutoAssignSimulateRequestModel {
  final String? categoryId;
  final String? categoryCode;
  final double latitude;
  final double longitude;
  final double? distanceWeight;
  final double? monthlyWorkloadWeight;
  final double? activeLoadWeight;
  final double? onTimeRateWeight;
  final double? maxRadiusKm;
  final int? maxConcurrentTasks;
  final int? targetMonthlyTasks;
  final int limit;

  const AutoAssignSimulateRequestModel({
    this.categoryId,
    this.categoryCode,
    required this.latitude,
    required this.longitude,
    this.distanceWeight,
    this.monthlyWorkloadWeight,
    this.activeLoadWeight,
    this.onTimeRateWeight,
    this.maxRadiusKm,
    this.maxConcurrentTasks,
    this.targetMonthlyTasks,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      if (categoryCode != null && categoryCode!.isNotEmpty)
        'categoryCode': categoryCode,
      'latitude': latitude,
      'longitude': longitude,
      if (distanceWeight != null) 'distanceWeight': distanceWeight,
      if (monthlyWorkloadWeight != null)
        'monthlyWorkloadWeight': monthlyWorkloadWeight,
      if (activeLoadWeight != null) 'activeLoadWeight': activeLoadWeight,
      if (onTimeRateWeight != null) 'onTimeRateWeight': onTimeRateWeight,
      if (maxRadiusKm != null) 'maxRadiusKm': maxRadiusKm,
      if (maxConcurrentTasks != null)
        'maxConcurrentTasks': maxConcurrentTasks,
      if (targetMonthlyTasks != null)
        'targetMonthlyTasks': targetMonthlyTasks,
      'limit': limit,
    };
  }
}

class StaffWorkloadFairnessModel {
  final String staffId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? positionName;
  final String? baseAddress;
  final bool hasBaseLocation;
  final int activeProcessingCount;
  final int maxConcurrentTasks;
  final int monthlyWorkload;
  final int targetMonthlyTasks;
  final double onTimeRate30d;
  final double monthlyLoadRatio;

  const StaffWorkloadFairnessModel({
    required this.staffId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.positionName,
    this.baseAddress,
    this.hasBaseLocation = false,
    this.activeProcessingCount = 0,
    this.maxConcurrentTasks = 10,
    this.monthlyWorkload = 0,
    this.targetMonthlyTasks = 20,
    this.onTimeRate30d = 85.0,
    this.monthlyLoadRatio = 0.0,
  });

  factory StaffWorkloadFairnessModel.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadFairnessModel(
      staffId: (json['staff_id'] ?? json['staffId'])?.toString() ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      positionName: (json['position_name'] ?? json['positionName']) as String?,
      baseAddress: (json['base_address'] ?? json['baseAddress']) as String?,
      hasBaseLocation:
          (json['has_base_location'] ?? json['hasBaseLocation']) as bool? ??
              false,
      activeProcessingCount:
          ((json['active_processing_count'] ?? json['activeProcessingCount'])
                      as num?)
                  ?.toInt() ??
              0,
      maxConcurrentTasks:
          ((json['max_concurrent_tasks'] ?? json['maxConcurrentTasks']) as num?)
                  ?.toInt() ??
              10,
      monthlyWorkload:
          ((json['monthly_workload'] ?? json['monthlyWorkload']) as num?)
                  ?.toInt() ??
              0,
      targetMonthlyTasks:
          ((json['target_monthly_tasks'] ?? json['targetMonthlyTasks']) as num?)
                  ?.toInt() ??
              20,
      onTimeRate30d:
          ((json['on_time_rate_30d'] ?? json['onTimeRate30d']) as num?)
                  ?.toDouble() ??
              85.0,
      monthlyLoadRatio:
          ((json['monthly_load_ratio'] ?? json['monthlyLoadRatio']) as num?)
                  ?.toDouble() ??
              0.0,
    );
  }
}

class AutoAssignAnalyticsModel {
  final int totalDecisions;
  final int autoAssignedCount;
  final int recommendAssignedCount;
  final int fallbackCount;
  final int overriddenCount;
  final double autoAssignSuccessRate;
  final double adminAcceptanceRate;
  final double monthlyFairnessIndex;
  final double averageMonthlyWorkload;
  final int minMonthlyWorkload;
  final int maxMonthlyWorkload;
  final double workloadStandardDeviation;
  final List<StaffWorkloadFairnessModel> staffWorkloads;

  const AutoAssignAnalyticsModel({
    this.totalDecisions = 0,
    this.autoAssignedCount = 0,
    this.recommendAssignedCount = 0,
    this.fallbackCount = 0,
    this.overriddenCount = 0,
    this.autoAssignSuccessRate = 100.0,
    this.adminAcceptanceRate = 100.0,
    this.monthlyFairnessIndex = 100.0,
    this.averageMonthlyWorkload = 0.0,
    this.minMonthlyWorkload = 0,
    this.maxMonthlyWorkload = 0,
    this.workloadStandardDeviation = 0.0,
    this.staffWorkloads = const [],
  });

  factory AutoAssignAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final rawStaff = json['staff_workloads'] ?? json['staffWorkloads'];
    final List<StaffWorkloadFairnessModel> parsedStaff = rawStaff is List
        ? rawStaff
            .whereType<Map<String, dynamic>>()
            .map(StaffWorkloadFairnessModel.fromJson)
            .toList()
        : const [];

    return AutoAssignAnalyticsModel(
      totalDecisions:
          ((json['total_decisions'] ?? json['totalDecisions']) as num?)
                  ?.toInt() ??
              0,
      autoAssignedCount:
          ((json['auto_assigned_count'] ?? json['autoAssignedCount']) as num?)
                  ?.toInt() ??
              0,
      recommendAssignedCount: ((json['recommend_assigned_count'] ??
                  json['recommendAssignedCount']) as num?)
              ?.toInt() ??
          0,
      fallbackCount:
          ((json['fallback_count'] ?? json['fallbackCount']) as num?)
                  ?.toInt() ??
              0,
      overriddenCount:
          ((json['overridden_count'] ?? json['overriddenCount']) as num?)
                  ?.toInt() ??
              0,
      autoAssignSuccessRate: ((json['auto_assign_success_rate'] ??
                  json['autoAssignSuccessRate']) as num?)
              ?.toDouble() ??
          100.0,
      adminAcceptanceRate: ((json['admin_acceptance_rate'] ??
                  json['adminAcceptanceRate']) as num?)
              ?.toDouble() ??
          100.0,
      monthlyFairnessIndex: ((json['monthly_fairness_index'] ??
                  json['monthlyFairnessIndex']) as num?)
              ?.toDouble() ??
          100.0,
      averageMonthlyWorkload: ((json['average_monthly_workload'] ??
                  json['averageMonthlyWorkload']) as num?)
              ?.toDouble() ??
          0.0,
      minMonthlyWorkload: ((json['min_monthly_workload'] ??
                  json['minMonthlyWorkload']) as num?)
              ?.toInt() ??
          0,
      maxMonthlyWorkload: ((json['max_monthly_workload'] ??
                  json['maxMonthlyWorkload']) as num?)
              ?.toInt() ??
          0,
      workloadStandardDeviation: ((json['workload_standard_deviation'] ??
                  json['workloadStandardDeviation']) as num?)
              ?.toDouble() ??
          0.0,
      staffWorkloads: parsedStaff,
    );
  }
}

class AssignmentDecisionLogItemModel {
  final String id;
  final String? reportId;
  final String? reportTitle;
  final String? categoryId;
  final String? categoryCode;
  final String? categoryNameVi;
  final String? categoryNameEn;
  final String? modeAtDecision;
  final String? source;
  final String? outcome;
  final String? selectedStaffId;
  final String? selectedStaffName;
  final String? selectedStaffPositionName;
  final int? eligibleCandidateCount;
  final double? distanceKm;
  final double? distanceScore;
  final int? monthlyWorkload;
  final double? monthlyWorkloadScore;
  final int? activeProcessingCount;
  final double? activeLoadScore;
  final double? onTimeRate30d;
  final double? onTimeRateScore;
  final double? finalScore;
  final String? fallbackReason;
  final String? fallbackMessage;
  final String? overriddenByAdminId;
  final String? overriddenToStaffId;
  final String? overriddenToStaffName;
  final DateTime? overriddenAt;
  final DateTime? createdAt;

  const AssignmentDecisionLogItemModel({
    required this.id,
    this.reportId,
    this.reportTitle,
    this.categoryId,
    this.categoryCode,
    this.categoryNameVi,
    this.categoryNameEn,
    this.modeAtDecision,
    this.source,
    this.outcome,
    this.selectedStaffId,
    this.selectedStaffName,
    this.selectedStaffPositionName,
    this.eligibleCandidateCount,
    this.distanceKm,
    this.distanceScore,
    this.monthlyWorkload,
    this.monthlyWorkloadScore,
    this.activeProcessingCount,
    this.activeLoadScore,
    this.onTimeRate30d,
    this.onTimeRateScore,
    this.finalScore,
    this.fallbackReason,
    this.fallbackMessage,
    this.overriddenByAdminId,
    this.overriddenToStaffId,
    this.overriddenToStaffName,
    this.overriddenAt,
    this.createdAt,
  });

  factory AssignmentDecisionLogItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentDecisionLogItemModel(
      id: json['id']?.toString() ?? '',
      reportId: (json['report_id'] ?? json['reportId'])?.toString(),
      reportTitle: (json['report_title'] ?? json['reportTitle']) as String?,
      categoryId: (json['category_id'] ?? json['categoryId'])?.toString(),
      categoryCode: (json['category_code'] ?? json['categoryCode']) as String?,
      categoryNameVi:
          (json['category_name_vi'] ?? json['categoryNameVi']) as String?,
      categoryNameEn:
          (json['category_name_en'] ?? json['categoryNameEn']) as String?,
      modeAtDecision:
          (json['mode_at_decision'] ?? json['modeAtDecision']) as String?,
      source: json['source'] as String?,
      outcome: json['outcome'] as String?,
      selectedStaffId:
          (json['selected_staff_id'] ?? json['selectedStaffId'])?.toString(),
      selectedStaffName:
          (json['selected_staff_name'] ?? json['selectedStaffName']) as String?,
      selectedStaffPositionName: (json['selected_staff_position_name'] ??
          json['selectedStaffPositionName']) as String?,
      eligibleCandidateCount: ((json['eligible_candidate_count'] ??
              json['eligibleCandidateCount']) as num?)
          ?.toInt(),
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
      finalScore:
          ((json['final_score'] ?? json['finalScore']) as num?)?.toDouble(),
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
    );
  }
}

class AssignmentDecisionLogPageModel {
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final List<AssignmentDecisionLogItemModel> content;

  const AssignmentDecisionLogPageModel({
    this.currentPage = 1,
    this.pageSize = 15,
    this.totalPages = 0,
    this.totalElements = 0,
    this.content = const [],
  });

  factory AssignmentDecisionLogPageModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final List<AssignmentDecisionLogItemModel> parsedContent =
        rawContent is List
            ? rawContent
                .whereType<Map<String, dynamic>>()
                .map(AssignmentDecisionLogItemModel.fromJson)
                .toList()
            : const [];

    return AssignmentDecisionLogPageModel(
      currentPage:
          ((json['currentPage'] ?? json['current_page']) as num?)?.toInt() ?? 1,
      pageSize:
          ((json['pageSize'] ?? json['page_size']) as num?)?.toInt() ?? 15,
      totalPages:
          ((json['totalPages'] ?? json['total_pages']) as num?)?.toInt() ?? 0,
      totalElements:
          ((json['totalElements'] ?? json['total_elements']) as num?)
                  ?.toInt() ??
              parsedContent.length,
      content: parsedContent,
    );
  }
}
