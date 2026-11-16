import 'package:mobile_shared/core/utils/report_deadline_helper.dart';

enum ReportStatus { processed, processing, pending, rejected, unknown }
enum ReportSeverity { low, medium, high, critical, unknown }

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
  final DateTime? assignedAt;
  final String? userId;
  final String? userName;
  final String? userAvatarUrl;
  final bool isAnonymous;
  final ReportSeverity severity;
  final bool? isReviewResolved;
  final DateTime? deadline;
  final DateTime? resolvedAt;
  final bool? serverIsOverdue;
  final int? serverRemainingDays;

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
    this.assignedAt,
    this.userId,
    this.userName,
    this.userAvatarUrl,
    this.isAnonymous = false,
    this.severity = ReportSeverity.unknown,
    this.isReviewResolved,
    this.deadline,
    this.resolvedAt,
    this.serverIsOverdue,
    this.serverRemainingDays,
  });

  bool get isDangerous =>
      severity == ReportSeverity.high || severity == ReportSeverity.critical;

  /// Người dân đánh giá chưa thoả đáng → admin mở lại, staff phải xử lý lại.
  bool get needsRehandling =>
      status == ReportStatus.processing && isReviewResolved == false;

  bool get isOverdue => ReportDeadlineHelper.isOverdue(
        status: status.name,
        deadline: deadline,
        resolvedAt: resolvedAt,
        serverIsOverdue: serverIsOverdue,
      );

  int? get remainingDays => ReportDeadlineHelper.remainingDays(
        status: status.name,
        deadline: deadline,
        resolvedAt: resolvedAt,
        serverIsOverdue: serverIsOverdue,
        serverRemainingDays: serverRemainingDays,
      );

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: mapStatus(json['status'] as String?),
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedAt: (json['assigned_at'] ?? json['assignedAt']) != null
          ? DateTime.tryParse((json['assigned_at'] ?? json['assignedAt']).toString())
          : null,
      userId: (json['userId'] ?? json['user_id']) as String?,
      userName: json['userName'] as String? ?? json['user_name'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? json['user_avatar_url'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? json['is_anonymous'] as bool? ?? false,
      severity: mapSeverity(json['severity'] as String?),
      isReviewResolved: json['isReviewResolved'] as bool? ?? json['is_review_resolved'] as bool?,
      deadline: (json['deadline'] ?? json['report_deadline']) != null
          ? DateTime.tryParse((json['deadline'] ?? json['report_deadline']).toString())
          : null,
      resolvedAt: (json['resolvedAt'] ?? json['resolved_at']) != null
          ? DateTime.tryParse((json['resolvedAt'] ?? json['resolved_at']).toString())
          : null,
      serverIsOverdue: (json['isOverdue'] ?? json['is_overdue']) as bool?,
      serverRemainingDays: ((json['remainingDays'] ?? json['remaining_days']) as num?)?.toInt(),
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
      'assigned_at': assignedAt?.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'is_anonymous': isAnonymous,
      'severity': severity.name,
      'isReviewResolved': isReviewResolved,
      'deadline': deadline?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'is_overdue': serverIsOverdue,
      'remaining_days': serverRemainingDays,
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
    String? userId,
    DateTime? resolvedAt,
    bool? serverIsOverdue,
    int? serverRemainingDays,
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
      assignedAt: assignedAt,
      userId: userId ?? this.userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      isAnonymous: isAnonymous,
      severity: severity,
      isReviewResolved: isReviewResolved,
      deadline: deadline,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      serverIsOverdue: serverIsOverdue ?? this.serverIsOverdue,
      serverRemainingDays: serverRemainingDays ?? this.serverRemainingDays,
    );
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

  static ReportSeverity mapSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'low': return ReportSeverity.low;
      case 'medium': return ReportSeverity.medium;
      case 'high': return ReportSeverity.high;
      case 'critical': return ReportSeverity.critical;
      default: return ReportSeverity.unknown;
    }
  }
}
