enum ReportStatus { processed, processing, pending, rejected, unknown }

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
}
