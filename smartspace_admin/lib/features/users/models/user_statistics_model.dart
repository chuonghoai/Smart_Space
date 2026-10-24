class UserStatisticsModel {
  final int totalUsers;
  final int newUsers;
  final int newUsersPrevious;
  final int activeReporters;
  final int reports;
  final int reportsPrevious;
  final List<TopReporterItem> topReporters;

  const UserStatisticsModel({
    required this.totalUsers,
    required this.newUsers,
    required this.newUsersPrevious,
    required this.activeReporters,
    required this.reports,
    required this.reportsPrevious,
    required this.topReporters,
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    final topList = json['topReporters'] as List<dynamic>? ?? [];
    return UserStatisticsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      newUsers: (json['newUsers'] as num?)?.toInt() ?? 0,
      newUsersPrevious: (json['newUsersPrevious'] as num?)?.toInt() ?? 0,
      activeReporters: (json['activeReporters'] as num?)?.toInt() ?? 0,
      reports: (json['reports'] as num?)?.toInt() ?? 0,
      reportsPrevious: (json['reportsPrevious'] as num?)?.toInt() ?? 0,
      topReporters: topList
          .map((e) => TopReporterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// % người dùng đã gửi báo cáo trong 30 ngày. Null khi chưa có người dùng.
  double? get activeReporterRatio =>
      totalUsers == 0 ? null : activeReporters / totalUsers;
}

class TopReporterItem {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int reportCount;

  const TopReporterItem({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.reportCount,
  });

  factory TopReporterItem.fromJson(Map<String, dynamic> json) {
    return TopReporterItem(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// % thay đổi so với kỳ trước. Null khi kỳ trước = 0 (không so sánh được).
double? percentChange(int current, int previous) {
  if (previous == 0) return null;
  return (current - previous) / previous * 100;
}
