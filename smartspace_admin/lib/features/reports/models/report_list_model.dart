
class ReportListItem {
  final String id;
  final String title;
  final String status;
  final String? severity;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? address;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;
  final String? userName;
  final String? userEmail;

  const ReportListItem({
    required this.id,
    required this.title,
    required this.status,
    this.severity,
    this.createdAt,
    this.imageUrl,
    this.address,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
    this.userName,
    this.userEmail,
  });

  factory ReportListItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final raw = json['createdAt'] ?? json['created_at'];
    if (raw != null) createdAt = DateTime.tryParse(raw.toString());
    return ReportListItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      severity: json['severity']?.toString().toLowerCase(),
      createdAt: createdAt,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      address: json['address']?.toString(),
      assignedStaffName: (json['assignedStaffName'] ?? json['assigned_staff_name'])?.toString(),
      assignedStaffAvatarUrl: (json['assignedStaffAvatarUrl'] ?? json['assigned_staff_avatar_url'])?.toString(),
      userName: json['userName']?.toString() ?? json['user_name']?.toString(),
      userEmail: json['userEmail']?.toString() ?? json['user_email']?.toString(),
    );
  }

  ReportListItem copyWith({String? status}) => ReportListItem(
        id: id,
        title: title,
        status: status ?? this.status,
        severity: severity,
        createdAt: createdAt,
        imageUrl: imageUrl,
        address: address,
        assignedStaffName: assignedStaffName,
        assignedStaffAvatarUrl: assignedStaffAvatarUrl,
        userName: userName,
        userEmail: userEmail,
      );
}

class ReportListData {
  final List<ReportListItem> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;

  const ReportListData({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
  });

  bool get hasNextPage => currentPage < totalPages;

  static const empty = ReportListData(
    items: [],
    currentPage: 1,
    totalPages: 1,
    totalElements: 0,
    pageSize: 20,
  );

  factory ReportListData.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'] as Map<String, dynamic>? ?? {};
    final content = (reports['content'] as List<dynamic>? ?? [])
        .map((e) => ReportListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReportListData(
      items: content,
      currentPage: (reports['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (reports['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (reports['totalElements'] as num?)?.toInt() ?? 0,
      pageSize: (reports['pageSize'] as num?)?.toInt() ?? 20,
    );
  }
}
