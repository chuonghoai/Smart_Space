class RecentReportModel {
  final String id;
  final String title;
  final String? status;
  final String? severity;
  final String? createdAt;
  final String? imageUrl;
  final String? address;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;

  const RecentReportModel({
    required this.id,
    required this.title,
    this.status,
    this.severity,
    this.createdAt,
    this.imageUrl,
    this.address,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
  });

  factory RecentReportModel.fromJson(Map<String, dynamic> json) {
    // Parse single image url or first of image_urls
    String? imgUrl = json['image_url']?.toString() ?? json['imageUrl']?.toString();
    if (imgUrl == null || imgUrl.isEmpty) {
      final imgUrls = json['image_urls'] ?? json['images'];
      if (imgUrls is List && imgUrls.isNotEmpty) {
        imgUrl = imgUrls.first?.toString();
      } else if (imgUrls is String && imgUrls.isNotEmpty) {
        imgUrl = imgUrls.split(',').first.trim();
      }
    }

    return RecentReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString(),
      severity: json['severity']?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
      imageUrl: imgUrl,
      address: json['address']?.toString(),
      assignedStaffName: (json['assigned_staff_name'] ?? json['assignedStaffName'])?.toString(),
      assignedStaffAvatarUrl: (json['assigned_staff_avatar_url'] ?? json['assignedStaffAvatarUrl'])?.toString(),
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
      'address': address,
      'assignedStaffName': assignedStaffName,
      'assignedStaffAvatarUrl': assignedStaffAvatarUrl,
    };
  }
}
