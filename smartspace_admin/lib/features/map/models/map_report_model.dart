class MapReportModel {
  final String id;
  final String title;
  final String status;
  final String? severity;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? address;
  final DateTime? createdAt;

  const MapReportModel({
    required this.id,
    required this.title,
    required this.status,
    this.severity,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.address,
    this.createdAt,
  });

  factory MapReportModel.fromJson(Map<String, dynamic> json) {
    return MapReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      severity: json['severity']?.toString().toLowerCase(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      address: json['address']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isDangerous => severity == 'high' || severity == 'critical';
}
