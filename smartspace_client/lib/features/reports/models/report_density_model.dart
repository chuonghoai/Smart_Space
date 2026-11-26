import 'dart:convert';
import 'package:flutter/material.dart';

enum DensityLevel {
  low,
  medium,
  high,
}

class ReportDensityCell {
  final String cellId;
  final int count;
  final DensityLevel level;
  final Color color;
  final double latitude;
  final double longitude;
  final List<List<double>> coordinates; // [lat, lng]

  const ReportDensityCell({
    required this.cellId,
    required this.count,
    required this.level,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.coordinates,
  });

  factory ReportDensityCell.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['level'] as String? ?? 'LOW').toUpperCase();
    final level = switch (levelStr) {
      'MEDIUM' => DensityLevel.medium,
      'HIGH' => DensityLevel.high,
      _ => DensityLevel.low,
    };

    final colorHex = json['color'] as String? ?? '#22C55E';
    final color = _parseHexColor(colorHex);

    final rawCoords = json['coordinates'] as List<dynamic>? ?? [];
    final coordinates = rawCoords.map((pt) {
      if (pt is List) {
        return pt.map((v) => (v as num).toDouble()).toList();
      }
      return <double>[];
    }).where((pt) => pt.length >= 2).toList();

    return ReportDensityCell(
      cellId: json['cellId'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      level: level,
      color: color,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coordinates: coordinates,
    );
  }

  static Color _parseHexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF22C55E);
    }
  }
}

class ReportDensityResult {
  final int resolution;
  final double zoom;
  final int totalCells;
  final bool truncated;
  final List<ReportDensityCell> cells;
  final Map<String, dynamic> geojson;

  const ReportDensityResult({
    required this.resolution,
    required this.zoom,
    required this.totalCells,
    required this.truncated,
    required this.cells,
    required this.geojson,
  });

  factory ReportDensityResult.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'] as List<dynamic>? ?? [];
    final cells = rawCells
        .map((c) => ReportDensityCell.fromJson(c as Map<String, dynamic>))
        .toList();

    return ReportDensityResult(
      resolution: json['resolution'] as int? ?? 11,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 14.0,
      totalCells: json['totalCells'] as int? ?? cells.length,
      truncated: json['truncated'] as bool? ?? false,
      cells: cells,
      geojson: json['geojson'] as Map<String, dynamic>? ?? const {},
    );
  }

  String get geojsonString => jsonEncode(geojson);
}

