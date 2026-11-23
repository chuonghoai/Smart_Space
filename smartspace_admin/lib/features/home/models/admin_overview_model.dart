class VolumeSpikeAlert {
  final bool isSpike;
  final bool insufficientData;
  final int todayCount;
  final double baselineAvg14d;
  final double baselineStdDev14d;
  final double zScore;
  final int activeDays;

  const VolumeSpikeAlert({
    this.isSpike = false,
    this.insufficientData = true,
    this.todayCount = 0,
    this.baselineAvg14d = 0.0,
    this.baselineStdDev14d = 0.0,
    this.zScore = 0.0,
    this.activeDays = 0,
  });

  factory VolumeSpikeAlert.fromJson(Map<String, dynamic> json) {
    return VolumeSpikeAlert(
      isSpike: (json['isSpike'] as bool?) ?? (json['spike'] as bool?) ?? false,
      insufficientData: json['insufficientData'] as bool? ?? true,
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      baselineAvg14d: (json['baselineAvg14d'] as num?)?.toDouble() ?? 0.0,
      baselineStdDev14d: (json['baselineStdDev14d'] as num?)?.toDouble() ?? 0.0,
      zScore: (json['zScore'] as num?)?.toDouble() ?? 0.0,
      activeDays: (json['activeDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyPulseItem {
  final String date;
  final int inflow;
  final int outflow;

  const DailyPulseItem({
    required this.date,
    this.inflow = 0,
    this.outflow = 0,
  });

  factory DailyPulseItem.fromJson(Map<String, dynamic> json) {
    return DailyPulseItem(
      date: json['date']?.toString() ?? '',
      inflow: (json['inflow'] as num?)?.toInt() ?? 0,
      outflow: (json['outflow'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminOverviewModel {
  final int userCount;
  final int staffCount;
  final int adminCount;
  final int issueCount;
  final int pendingCount;
  final int processingCount; // Không gồm báo cáo xử lý lại
  final int rehandlingCount; // Chờ giao lại + đang làm lại
  final int unsatisfactoryProcessedCount;
  final int rehandlingProcessingCount;
  final VolumeSpikeAlert? volumeSpike;
  final int atRiskCount;
  final int pendingAtRiskCount;
  final int processingAtRiskCount;
  final int overloadedStaffCount;
  final int pendingOver24hCount;
  final List<DailyPulseItem> pulse7Days;

  const AdminOverviewModel({
    required this.userCount,
    required this.staffCount,
    required this.adminCount,
    required this.issueCount,
    this.pendingCount = 0,
    this.processingCount = 0,
    this.rehandlingCount = 0,
    this.unsatisfactoryProcessedCount = 0,
    this.rehandlingProcessingCount = 0,
    this.volumeSpike,
    this.atRiskCount = 0,
    this.pendingAtRiskCount = 0,
    this.processingAtRiskCount = 0,
    this.overloadedStaffCount = 0,
    this.pendingOver24hCount = 0,
    this.pulse7Days = const [],
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    final spikeRaw = json['volumeSpike'];
    final pulseRaw = json['pulse7Days'] as List<dynamic>? ?? const [];
    return AdminOverviewModel(
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      rehandlingCount: (json['rehandlingCount'] as num?)?.toInt() ?? 0,
      unsatisfactoryProcessedCount: (json['unsatisfactoryProcessedCount'] as num?)?.toInt() ?? 0,
      rehandlingProcessingCount: (json['rehandlingProcessingCount'] as num?)?.toInt() ?? 0,
      volumeSpike: spikeRaw is Map<String, dynamic>
          ? VolumeSpikeAlert.fromJson(spikeRaw)
          : null,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
      pendingAtRiskCount: (json['pendingAtRiskCount'] as num?)?.toInt() ?? 0,
      processingAtRiskCount: (json['processingAtRiskCount'] as num?)?.toInt() ?? 0,
      overloadedStaffCount: (json['overloadedStaffCount'] as num?)?.toInt() ?? 0,
      pendingOver24hCount: (json['pendingOver24hCount'] as num?)?.toInt() ?? 0,
      pulse7Days: pulseRaw
          .map((e) => DailyPulseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCount': userCount,
      'staffCount': staffCount,
      'adminCount': adminCount,
      'issueCount': issueCount,
      'pendingCount': pendingCount,
      'processingCount': processingCount,
      'rehandlingCount': rehandlingCount,
      'unsatisfactoryProcessedCount': unsatisfactoryProcessedCount,
      'rehandlingProcessingCount': rehandlingProcessingCount,
      'atRiskCount': atRiskCount,
      'pendingAtRiskCount': pendingAtRiskCount,
      'processingAtRiskCount': processingAtRiskCount,
      'overloadedStaffCount': overloadedStaffCount,
      'pendingOver24hCount': pendingOver24hCount,
    };
  }

  AdminOverviewModel copyWith({
    int? userCount,
    int? staffCount,
    int? adminCount,
    int? issueCount,
    int? pendingCount,
    int? processingCount,
    int? rehandlingCount,
    int? unsatisfactoryProcessedCount,
    int? rehandlingProcessingCount,
    VolumeSpikeAlert? volumeSpike,
    int? atRiskCount,
    int? pendingAtRiskCount,
    int? processingAtRiskCount,
    int? overloadedStaffCount,
    int? pendingOver24hCount,
    List<DailyPulseItem>? pulse7Days,
  }) {
    return AdminOverviewModel(
      userCount: userCount ?? this.userCount,
      staffCount: staffCount ?? this.staffCount,
      adminCount: adminCount ?? this.adminCount,
      issueCount: issueCount ?? this.issueCount,
      pendingCount: pendingCount ?? this.pendingCount,
      processingCount: processingCount ?? this.processingCount,
      rehandlingCount: rehandlingCount ?? this.rehandlingCount,
      unsatisfactoryProcessedCount: unsatisfactoryProcessedCount ?? this.unsatisfactoryProcessedCount,
      rehandlingProcessingCount: rehandlingProcessingCount ?? this.rehandlingProcessingCount,
      volumeSpike: volumeSpike ?? this.volumeSpike,
      atRiskCount: atRiskCount ?? this.atRiskCount,
      pendingAtRiskCount: pendingAtRiskCount ?? this.pendingAtRiskCount,
      processingAtRiskCount: processingAtRiskCount ?? this.processingAtRiskCount,
      overloadedStaffCount: overloadedStaffCount ?? this.overloadedStaffCount,
      pendingOver24hCount: pendingOver24hCount ?? this.pendingOver24hCount,
      pulse7Days: pulse7Days ?? this.pulse7Days,
    );
  }
}
