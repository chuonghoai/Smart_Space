class ReportDetailModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String? severity;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String> images;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userPhone;
  final String? userAvatarUrl;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedStaffPhone;
  final String? assignedStaffEmail;
  final String? assignedStaffAvatarUrl;

  ReportDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.severity,
    this.latitude,
    this.longitude,
    this.address,
    required this.images,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhone,
    this.userAvatarUrl,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedStaffPhone,
    this.assignedStaffEmail,
    this.assignedStaffAvatarUrl,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse images list from image_urls or images
    final rawImages = json['image_urls'] ?? json['images'] ?? json['imageUrls'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      parsedImages = rawImages
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    // Fallback to single image_url / imageUrl if list is empty
    if (parsedImages.isEmpty) {
      final singleImage = json['image_url'] ?? json['imageUrl'];
      if (singleImage != null && singleImage.toString().trim().isNotEmpty) {
        parsedImages.add(singleImage.toString().trim());
      }
    }

    return ReportDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: (json['status'] as String?)?.toUpperCase() ?? 'PENDING',
      severity: json['severity'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      images: parsedImages,
      isAnonymous: (json['is_anonymous'] ?? json['isAnonymous']) as bool? ?? false,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.tryParse((json['updated_at'] ?? json['updatedAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      userName: (json['user_name'] ?? json['userName']) as String?,
      userPhone: (json['user_phone'] ?? json['userPhone']) as String?,
      userAvatarUrl: (json['user_avatar_url'] ?? json['userAvatarUrl']) as String?,
      assignedStaffId: (json['assigned_staff_id'] ?? json['assignedStaffId'])?.toString(),
      assignedStaffName: (json['assigned_staff_name'] ?? json['assignedStaffName']) as String?,
      assignedStaffPhone: (json['assigned_staff_phone'] ?? json['assignedStaffPhone']) as String?,
      assignedStaffEmail: (json['assigned_staff_email'] ?? json['assignedStaffEmail']) as String?,
      assignedStaffAvatarUrl: (json['assigned_staff_avatar_url'] ?? json['assignedStaffAvatarUrl']) as String?,
    );
  }

  ReportDetailModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? severity,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? images,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userPhone,
    String? userAvatarUrl,
    String? assignedStaffId,
    String? assignedStaffName,
    String? assignedStaffPhone,
    String? assignedStaffEmail,
    String? assignedStaffAvatarUrl,
  }) {
    return ReportDetailModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      images: images ?? this.images,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedStaffPhone: assignedStaffPhone ?? this.assignedStaffPhone,
      assignedStaffEmail: assignedStaffEmail ?? this.assignedStaffEmail,
      assignedStaffAvatarUrl: assignedStaffAvatarUrl ?? this.assignedStaffAvatarUrl,
    );
  }
}
