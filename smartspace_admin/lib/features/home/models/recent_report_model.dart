import 'package:mobile_shared/core/utils/report_deadline_helper.dart';

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
  final bool isAnonymous;
  final bool? isReviewResolved;
  final String? deadline;
  final String? resolvedAt;
  final bool? serverIsOverdue;
  final int? serverRemainingDays;

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
    this.isAnonymous = false,
    this.isReviewResolved,
    this.deadline,
    this.resolvedAt,
    this.serverIsOverdue,
    this.serverRemainingDays,
  });

  DateTime? get deadlineDate =>
      deadline != null ? DateTime.tryParse(deadline!) : null;

  DateTime? get resolvedAtDate =>
      resolvedAt != null ? DateTime.tryParse(resolvedAt!) : null;

  bool get isOverdue => ReportDeadlineHelper.isOverdue(
        status: status ?? '',
        deadline: deadlineDate,
        resolvedAt: resolvedAtDate,
        serverIsOverdue: serverIsOverdue,
      );

  int? get remainingDays => ReportDeadlineHelper.remainingDays(
        status: status ?? '',
        deadline: deadlineDate,
        resolvedAt: resolvedAtDate,
        serverIsOverdue: serverIsOverdue,
        serverRemainingDays: serverRemainingDays,
      );

  bool get isOverdueActive => isOverdue;

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
      isAnonymous: (json['is_anonymous'] ?? json['isAnonymous']) as bool? ?? false,
      isReviewResolved: json['isReviewResolved'] as bool? ?? json['is_review_resolved'] as bool?,
      deadline: (json['deadline'] ?? json['report_deadline'])?.toString(),
      resolvedAt: (json['resolvedAt'] ?? json['resolved_at'])?.toString(),
      serverIsOverdue: (json['isOverdue'] ?? json['is_overdue']) as bool?,
      serverRemainingDays: (json['remainingDays'] ?? json['remaining_days'] as num?)?.toInt(),
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
      'is_anonymous': isAnonymous,
      'deadline': deadline,
      'resolvedAt': resolvedAt,
    };
  }
}
