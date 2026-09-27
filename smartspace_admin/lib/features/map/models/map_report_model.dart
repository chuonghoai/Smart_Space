import 'package:flutter/material.dart';

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

  /// Semantic color for marker border based on status.
  /// Uses design system semantic colors.
  Color statusColor(ColorScheme scheme) {
    return switch (status) {
      'pending' => scheme.error,
      'processing' => const Color(0xFFF9A825), // warning light
      'processed' => const Color(0xFF2E7D32), // success light
      _ => scheme.outline, // rejected / unknown
    };
  }

  /// Dark-mode-aware semantic color.
  Color statusColorAdaptive(ColorScheme scheme, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return switch (status) {
        'pending' => const Color(0xFFEF5350),
        'processing' => const Color(0xFFFFCA28),
        'processed' => const Color(0xFF66BB6A),
        _ => scheme.outline,
      };
    }
    return statusColor(scheme);
  }
}
