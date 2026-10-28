import 'package:smartspace_staff/features/reports/models/report_model.dart';

class ReportDetailModel extends ReportModel {
  final List<String> imageUrls;
  final String? address; // Địa chỉ
  final String? locationDescription; // Mô tả chi tiết địa điểm
  final String? userPhone;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;
  final String? resolvedNote;
  final List<String>? resolvedImageUrls;
  final DateTime? resolvedAt;
  final int? rating;
  final String? reviewNote;
  final List<String>? reviewImageUrls;
  final DateTime? reviewedAt;
  final double? baseCommission;
  final double? deductedCommission;
  final double? finalCommission;
  final double? expectedCommission;
  final bool? commissionAwarded;
  final int? rehandlingPenaltyCount;

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
    super.isReviewResolved,

    required this.imageUrls,
    this.address,
    this.locationDescription,
    this.userPhone,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
    this.resolvedNote,
    this.resolvedImageUrls,
    this.resolvedAt,
    this.rating,
    this.reviewNote,
    this.reviewImageUrls,
    this.reviewedAt,
    this.baseCommission,
    this.deductedCommission,
    this.finalCommission,
    this.expectedCommission,
    this.commissionAwarded,
    this.rehandlingPenaltyCount,
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

    List<String>? parsedReviewImages;
    final rawReviewImages = json['review_image_urls'] ?? json['reviewImages'] ?? json['reviewImageUrls'];
    if (rawReviewImages != null) {
      if (rawReviewImages is List) {
        parsedReviewImages = List<String>.from(rawReviewImages);
      } else if (rawReviewImages is String) {
        parsedReviewImages = rawReviewImages
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
      userPhone: (json['user_phone'] ?? json['userPhone']) as String?,
      address: json['address'] as String?,
      locationDescription: json['location_description'] as String?,
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      assignedStaffId: json['assigned_staff_id'] as String?,
      assignedStaffName: json['assigned_staff_name'] as String?,
      assignedStaffAvatarUrl: json['assigned_staff_avatar_url'] as String?,
      resolvedNote: json['resolved_note'] as String?,
      resolvedImageUrls: json['resolved_image_urls'] != null
          ? (json['resolved_image_urls'] is List
              ? List<String>.from(json['resolved_image_urls'])
              : (json['resolved_image_urls'] as String).split(',').where((e) => e.isNotEmpty).toList())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      isReviewResolved: json['isReviewResolved'] as bool? ?? json['is_review_resolved'] as bool?,
      rating: (json['rating'] as num?)?.toInt(),
      reviewNote: (json['review_note'] ?? json['reviewNote']) as String?,
      reviewImageUrls: parsedReviewImages,
      reviewedAt: json['reviewed_at'] != null || json['reviewedAt'] != null
          ? DateTime.tryParse((json['reviewed_at'] ?? json['reviewedAt']).toString())
          : null,
      baseCommission: (json['base_commission'] as num?)?.toDouble(),
      deductedCommission: (json['deducted_commission'] as num?)?.toDouble(),
      finalCommission: (json['final_commission'] as num?)?.toDouble(),
      expectedCommission: (json['expected_commission'] as num?)?.toDouble(),
      commissionAwarded: json['commission_awarded'] as bool?,
      rehandlingPenaltyCount: (json['rehandling_penalty_count'] as num?)?.toInt(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['image_urls'] = imageUrls;
    map['severity'] = severity.name.toUpperCase();
    map['is_anonymous'] = isAnonymous;
    map['user_phone'] = userPhone;
    map['address'] = address;
    map['location_description'] = locationDescription;
    map['assigned_staff_id'] = assignedStaffId;
    map['assigned_staff_name'] = assignedStaffName;
    map['assigned_staff_avatar_url'] = assignedStaffAvatarUrl;
    map['resolved_note'] = resolvedNote;
    map['resolved_image_urls'] = resolvedImageUrls;
    map['resolved_at'] = resolvedAt?.toIso8601String();
    map['rating'] = rating;
    map['review_note'] = reviewNote;
    map['review_image_urls'] = reviewImageUrls;
    map['reviewed_at'] = reviewedAt?.toIso8601String();
    map['base_commission'] = baseCommission;
    map['deducted_commission'] = deductedCommission;
    map['final_commission'] = finalCommission;
    map['expected_commission'] = expectedCommission;
    map['commission_awarded'] = commissionAwarded;
    map['rehandling_penalty_count'] = rehandlingPenaltyCount;
    return map;
  }

  @override
  ReportDetailModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
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
    String? userPhone,
    String? address,
    String? locationDescription,
    String? assignedStaffId,
    String? assignedStaffName,
    String? assignedStaffAvatarUrl,
    String? resolvedNote,
    List<String>? resolvedImageUrls,
    DateTime? resolvedAt,
    bool? isReviewResolved,
    int? rating,
    String? reviewNote,
    List<String>? reviewImageUrls,
    DateTime? reviewedAt,
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
      userPhone: userPhone ?? this.userPhone,
      address: address ?? this.address,
      locationDescription: locationDescription ?? this.locationDescription,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedStaffAvatarUrl: assignedStaffAvatarUrl ?? this.assignedStaffAvatarUrl,
      resolvedNote: resolvedNote ?? this.resolvedNote,
      resolvedImageUrls: resolvedImageUrls ?? this.resolvedImageUrls,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isReviewResolved: isReviewResolved ?? this.isReviewResolved,
      rating: rating ?? this.rating,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewImageUrls: reviewImageUrls ?? this.reviewImageUrls,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
