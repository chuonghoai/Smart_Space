enum ReportStatus { processed, processing, pending, rejected, unknown }

enum EReportSeverity { low, medium, high, critical }

class ReportModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final ReportStatus status;
  final DateTime createdAt;
  final double? distanceInMeters;
  final bool? isReviewResolved;
  final EReportSeverity? severity;
  final String? userId;

  bool get isDangerous =>
      severity == EReportSeverity.high || severity == EReportSeverity.critical;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.distanceInMeters,
    this.isReviewResolved,
    this.severity,
    this.userId,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: mapStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      isReviewResolved: json['is_review_resolved'] as bool? ?? json['isReviewResolved'] as bool?,
      severity: mapSeverity(json['severity'] as String?),
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'is_review_resolved': isReviewResolved,
      'severity': severity?.name,
      'user_id': userId,
    };
  }

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    ReportStatus? status,
    DateTime? createdAt,
    double? distanceInMeters,
    bool? isReviewResolved,
    EReportSeverity? severity,
    String? userId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      isReviewResolved: isReviewResolved ?? this.isReviewResolved,
      severity: severity ?? this.severity,
      userId: userId ?? this.userId,
    );
  }

  /// Severity từ backend (`low|medium|high|critical`); null nếu chưa được đánh giá.
  static EReportSeverity? mapSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return EReportSeverity.critical;
      case 'high':
        return EReportSeverity.high;
      case 'medium':
        return EReportSeverity.medium;
      case 'low':
        return EReportSeverity.low;
      default:
        return null;
    }
  }

  static ReportStatus mapStatus(String? status) {
    switch (status) {
      case 'processed':
      case 'Đã xử lý':
        return ReportStatus.processed;
      case 'processing':
      case 'Đang xử lý':
        return ReportStatus.processing;
      case 'pending':
      case 'Đang chờ':
        return ReportStatus.pending;
      case 'rejected':
      case 'Từ chối':
        return ReportStatus.rejected;
      case 'unknown':
      case 'Khác':
        return ReportStatus.unknown;
      default:
        return ReportStatus.unknown;
    }
  }

  static String _statusToString(ReportStatus status) {
    return status.name;
  }
}
