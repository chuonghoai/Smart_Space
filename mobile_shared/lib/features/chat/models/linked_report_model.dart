class LinkedReportModel {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? status;
  final String? severity;
  final String? createdAt;
  final String? address;
  final bool? isReviewResolved;
  final bool? needsRehandling;

  const LinkedReportModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.status,
    this.severity,
    this.createdAt,
    this.address,
    this.isReviewResolved,
    this.needsRehandling,
  });

  bool get isRehandling =>
      needsRehandling == true ||
      (status?.toLowerCase() == 'processing' && isReviewResolved == false) ||
      (status?.toLowerCase() == 'processed' && isReviewResolved == false);

  factory LinkedReportModel.fromJson(Map<String, dynamic> json) {
    return LinkedReportModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String?,
      severity: json['severity'] as String?,
      createdAt: json['createdAt'] as String?,
      address: json['address'] as String?,
      isReviewResolved: json['isReviewResolved'] as bool?,
      needsRehandling: json['needsRehandling'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'status': status,
    'severity': severity,
    'createdAt': createdAt,
    'address': address,
    'isReviewResolved': isReviewResolved,
    'needsRehandling': needsRehandling,
  };
}
