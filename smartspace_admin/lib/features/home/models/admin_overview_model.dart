class AdminOverviewModel {
  final int userCount;
  final int staffCount;
  final int adminCount;
  final int issueCount;

  const AdminOverviewModel({
    required this.userCount,
    required this.staffCount,
    required this.adminCount,
    required this.issueCount,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminOverviewModel(
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCount': userCount,
      'staffCount': staffCount,
      'adminCount': adminCount,
      'issueCount': issueCount,
    };
  }
}
