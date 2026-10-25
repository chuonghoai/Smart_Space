class UserDetailModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? language;
  final String? status;
  final DateTime? createdAt;
  final UserReportStats reportStats;
  final List<UserRecentReport> recentReports;

  const UserDetailModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.language,
    this.status,
    this.createdAt,
    required this.reportStats,
    required this.recentReports,
  });

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    final recentList = json['recentReports'] as List<dynamic>? ?? [];
    return UserDetailModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      language: json['language'] as String?,
      status: json['status'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      reportStats: UserReportStats.fromJson(
        json['reportStats'] as Map<String, dynamic>? ?? {},
      ),
      recentReports: recentList
          .map((e) => UserRecentReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isBlocked => status == 'blocked';
}

class UserReportStats {
  final int total;
  final int pending;
  final int processing;
  final int processed;
  final int rejected;

  const UserReportStats({
    required this.total,
    required this.pending,
    required this.processing,
    required this.processed,
    required this.rejected,
  });

  factory UserReportStats.fromJson(Map<String, dynamic> json) {
    return UserReportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      processing: (json['processing'] as num?)?.toInt() ?? 0,
      processed: (json['processed'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserRecentReport {
  final String id;
  final String title;
  final String? status;
  final String? severity;
  final DateTime? createdAt;

  const UserRecentReport({
    required this.id,
    required this.title,
    this.status,
    this.severity,
    this.createdAt,
  });

  factory UserRecentReport.fromJson(Map<String, dynamic> json) {
    return UserRecentReport(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String?,
      severity: json['severity'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
