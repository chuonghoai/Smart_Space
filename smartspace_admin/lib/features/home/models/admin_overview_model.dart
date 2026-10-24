class AdminOverviewModel {
  final int userCount;
  final int staffCount;
  final int adminCount;
  final int issueCount;
  final int pendingCount;
  final int processingCount;
  final int unsatisfactoryProcessedCount;
  final int rehandlingProcessingCount;

  const AdminOverviewModel({
    required this.userCount,
    required this.staffCount,
    required this.adminCount,
    required this.issueCount,
    this.pendingCount = 0,
    this.processingCount = 0,
    this.unsatisfactoryProcessedCount = 0,
    this.rehandlingProcessingCount = 0,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminOverviewModel(
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      unsatisfactoryProcessedCount: (json['unsatisfactoryProcessedCount'] as num?)?.toInt() ?? 0,
      rehandlingProcessingCount: (json['rehandlingProcessingCount'] as num?)?.toInt() ?? 0,
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
      'unsatisfactoryProcessedCount': unsatisfactoryProcessedCount,
      'rehandlingProcessingCount': rehandlingProcessingCount,
    };
  }

  AdminOverviewModel copyWith({
    int? userCount,
    int? staffCount,
    int? adminCount,
    int? issueCount,
    int? pendingCount,
    int? processingCount,
    int? unsatisfactoryProcessedCount,
    int? rehandlingProcessingCount,
  }) {
    return AdminOverviewModel(
      userCount: userCount ?? this.userCount,
      staffCount: staffCount ?? this.staffCount,
      adminCount: adminCount ?? this.adminCount,
      issueCount: issueCount ?? this.issueCount,
      pendingCount: pendingCount ?? this.pendingCount,
      processingCount: processingCount ?? this.processingCount,
      unsatisfactoryProcessedCount: unsatisfactoryProcessedCount ?? this.unsatisfactoryProcessedCount,
      rehandlingProcessingCount: rehandlingProcessingCount ?? this.rehandlingProcessingCount,
    );
  }
}
