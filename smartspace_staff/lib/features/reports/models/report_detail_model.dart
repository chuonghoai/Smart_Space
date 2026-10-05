import 'package:smartspace_staff/features/reports/models/report_model.dart';

class ReportDetailModel extends ReportModel {
  final List<String> imageUrls;
  final String? address; // Địa chỉ
  final String? locationDescription; // Mô tả chi tiết địa điểm
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;

  ReportDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.latitude,
    required super.longitude,
    required super.status,
    required super.createdAt,
    super.distanceInMeters,
    super.assignedAt,
    super.userName,
    super.userAvatarUrl,
    required super.severity,
    required super.isAnonymous,

    required this.imageUrls,
    this.address,
    this.locationDescription,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
  }) : super(imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImageUrls = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImageUrls = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        parsedImageUrls = (json['image_urls'] as String)
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return ReportDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: ReportModel.mapStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString())
          : null,
      severity: ReportModel.mapSeverity(json['severity'] as String?),
      imageUrls: parsedImageUrls,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      address: json['address'] as String?,
      locationDescription: json['location_description'] as String?,
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      assignedStaffId: json['assigned_staff_id'] as String?,
      assignedStaffName: json['assigned_staff_name'] as String?,
      assignedStaffAvatarUrl: json['assigned_staff_avatar_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['image_urls'] = imageUrls;
    map['severity'] = severity.name.toUpperCase();
    map['is_anonymous'] = isAnonymous;
    map['address'] = address;
    map['location_description'] = locationDescription;
    map['assigned_staff_id'] = assignedStaffId;
    map['assigned_staff_name'] = assignedStaffName;
    map['assigned_staff_avatar_url'] = assignedStaffAvatarUrl;
    return map;
  }

  @override
  ReportDetailModel copyWith({
    String? id,
    String? title,
    String? description,
    String?
    imageUrl, // Note: not used but required for override signature match if any
    double? latitude,
    double? longitude,
    ReportStatus? status,
    DateTime? createdAt,
    double? distanceInMeters,
    ReportSeverity? severity,
    List<String>? imageUrls,
    bool? isAnonymous,
    String? userName,
    String? userAvatarUrl,
    String? address,
    String? locationDescription,
    String? assignedStaffId,
    String? assignedStaffName,
    String? assignedStaffAvatarUrl,
  }) {
    return ReportDetailModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      severity: severity ?? this.severity,
      imageUrls: imageUrls ?? this.imageUrls,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      address: address ?? this.address,
      locationDescription: locationDescription ?? this.locationDescription,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedStaffAvatarUrl: assignedStaffAvatarUrl ?? this.assignedStaffAvatarUrl,
    );
  }
}
