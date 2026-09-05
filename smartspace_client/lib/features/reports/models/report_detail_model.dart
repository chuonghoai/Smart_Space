import 'package:smartspace_client/features/reports/models/report_model.dart';

enum EReportSeverity { low, medium, high, critical }  

class ReportDetailModel extends ReportModel{
  final EReportSeverity severity;     // Mức độ ưu tiên/nguy hiểm
  final List<String> imageUrls;
  final bool isAnonymous;             // Ẩn danh
  final String? address;              // Địa chỉ
  final String? locationDescription;   // Mô tả chi tiết địa điểm

  ReportDetailModel({
    required super.id, 
    required super.title, 
    required super.description, 
    required super.latitude, 
    required super.longitude, 
    required super.status,
    required super.createdAt, 
    super.distanceInMeters,
    
    required this.severity, 
    required this.imageUrls, 
    required this.isAnonymous,
    this.address, 
    this.locationDescription,
  }) : super(imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImageUrls = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImageUrls = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        parsedImageUrls = (json['image_urls'] as String).split(',').where((e) => e.isNotEmpty).toList();
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
}