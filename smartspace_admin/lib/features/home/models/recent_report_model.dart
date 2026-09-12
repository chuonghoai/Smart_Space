class RecentReportModel {
  final String id;
  final String title;
  final String? status;
  final String? severity;
  final String? createdAt;
  final String? imageUrl;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;

  const RecentReportModel({
    required this.id,
    required this.title,
    this.status,
    this.severity,
    this.createdAt,
    this.imageUrl,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
  });

  factory RecentReportModel.fromJson(Map<String, dynamic> json) {
    return RecentReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString(),
      severity: json['severity']?.toString(),
      createdAt: json['createdAt']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      assignedStaffName: json['assignedStaffName']?.toString(),
      assignedStaffAvatarUrl: json['assignedStaffAvatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'severity': severity,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'assignedStaffName': assignedStaffName,
      'assignedStaffAvatarUrl': assignedStaffAvatarUrl,
    };
  }
}
