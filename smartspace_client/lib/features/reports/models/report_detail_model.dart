import 'package:smartspace_client/features/reports/models/report_model.dart';

enum EReportSeverity { low, medium, high, critical }

class ReportDetailModel extends ReportModel {
  final EReportSeverity severity; // Mức độ ưu tiên/nguy hiểm
  final List<String> imageUrls;
  final bool isAnonymous; // Ẩn danh
  final String? address; // Địa chỉ
  final String? locationDescription; // Mô tả chi tiết địa điểm
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedStaffAvatarUrl;
  final String? resolvedNote;
  final List<String> resolvedImageUrls;
  final DateTime? resolvedAt;
  final int? rating;
  final String? reviewNote;
  final List<String> reviewImageUrls;
  final DateTime? reviewedAt;

  bool get hasReviewed => reviewedAt != null || isReviewResolved != null;

  ReportDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.latitude,
    required super.longitude,
    required super.status,
    required super.createdAt,
    super.distanceInMeters,
    super.isReviewResolved,

    required this.severity,
    required this.imageUrls,
    required this.isAnonymous,
    this.address,
    this.locationDescription,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedStaffAvatarUrl,
    this.resolvedNote,
    this.resolvedImageUrls = const [],
    this.resolvedAt,
    this.rating,
    this.reviewNote,
    this.reviewImageUrls = const [],
    this.reviewedAt,
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

    List<String> parsedResolvedImageUrls = [];
    if (json['resolved_image_urls'] != null) {
      if (json['resolved_image_urls'] is List) {
        parsedResolvedImageUrls = List<String>.from(json['resolved_image_urls']);
      } else if (json['resolved_image_urls'] is String) {
        parsedResolvedImageUrls = (json['resolved_image_urls'] as String)
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    List<String> parsedReviewImageUrls = [];
    if (json['review_image_urls'] != null) {
      if (json['review_image_urls'] is List) {
        parsedReviewImageUrls = List<String>.from(json['review_image_urls']);
      } else if (json['review_image_urls'] is String) {
        parsedReviewImageUrls = (json['review_image_urls'] as String)
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
      severity: _mapSeverity(json['severity'] as String?),
      imageUrls: parsedImageUrls,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      address: json['address'] as String?,
      locationDescription: json['location_description'] as String?,
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      assignedStaffId: json['assigned_staff_id'] as String?,
      assignedStaffName: json['assigned_staff_name'] as String?,
      assignedStaffAvatarUrl: json['assigned_staff_avatar_url'] as String?,
      resolvedNote: json['resolved_note'] as String?,
      resolvedImageUrls: parsedResolvedImageUrls,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      isReviewResolved: json['is_review_resolved'] as bool?,
      rating: json['rating'] as int?,
      reviewNote: json['review_note'] as String?,
      reviewImageUrls: parsedReviewImageUrls,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['image_urls'] = imageUrls;
    map['severity'] = _severityToString(severity);
    map['is_anonymous'] = isAnonymous;
    map['address'] = address;
    map['location_description'] = locationDescription;
    map['assigned_staff_id'] = assignedStaffId;
    map['assigned_staff_name'] = assignedStaffName;
    map['assigned_staff_avatar_url'] = assignedStaffAvatarUrl;
    map['resolved_note'] = resolvedNote;
    map['resolved_image_urls'] = resolvedImageUrls;
    map['resolved_at'] = resolvedAt?.toIso8601String();
    map['is_review_resolved'] = isReviewResolved;
    map['rating'] = rating;
    map['review_note'] = reviewNote;
    map['review_image_urls'] = reviewImageUrls;
    map['reviewed_at'] = reviewedAt?.toIso8601String();
    return map;
  }

  static EReportSeverity _mapSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return EReportSeverity.critical;
      case 'high':
        return EReportSeverity.high;
      case 'medium':
        return EReportSeverity.medium;
      case 'low':
      default:
        return EReportSeverity.low;
    }
  }

  static String _severityToString(EReportSeverity severity) {
    return severity.name.toUpperCase();
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
    EReportSeverity? severity,
    List<String>? imageUrls,
    bool? isAnonymous,
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
