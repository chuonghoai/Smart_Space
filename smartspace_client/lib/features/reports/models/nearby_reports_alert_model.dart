class NearbyReportItemModel {
  final String id;
  final String title;
  final String? description;
  final List<String> imageUrls;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? status;
  final String? severity;
  final double? distanceInMeters;
  final DateTime? createdAt;

  NearbyReportItemModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrls = const [],
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.status,
    this.severity,
    this.distanceInMeters,
    this.createdAt,
  });

  /// Returns all available images, falling back to imageUrl if imageUrls is empty
  List<String> get allImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) return [imageUrl!.trim()];
    return [];
  }

  factory NearbyReportItemModel.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['image_urls'] is List) {
      imgs = (json['image_urls'] as List).map((e) => e.toString()).toList();
    }
    return NearbyReportItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrls: imgs,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String?,
      severity: json['severity'] as String?,
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'severity': severity,
      'distance_in_meters': distanceInMeters,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class NearbyReportsAlertResponse {
  final int count;
  final double? nearestDistance;
  final List<NearbyReportItemModel> reports;

  NearbyReportsAlertResponse({
    required this.count,
    this.nearestDistance,
    this.reports = const [],
  });

  factory NearbyReportsAlertResponse.fromJson(Map<String, dynamic> json) {
    List<NearbyReportItemModel> list = [];
    if (json['reports'] is List) {
      list = (json['reports'] as List)
          .map((e) => NearbyReportItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return NearbyReportsAlertResponse(
      count: (json['count'] as num?)?.toInt() ?? list.length,
      nearestDistance: (json['nearest_distance'] as num?)?.toDouble(),
      reports: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'nearest_distance': nearestDistance,
      'reports': reports.map((e) => e.toJson()).toList(),
    };
  }
}
