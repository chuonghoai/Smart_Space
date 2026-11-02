import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/report_density_model.dart';

void main() {
  group('ReportDensityModel Tests', () {
    test('ReportDensityCell parses LOW level correctly', () {
      final json = {
        'cellId': '8b2f567406a0fff',
        'count': 2,
        'level': 'LOW',
        'color': '#22C55E',
        'latitude': 10.7769,
        'longitude': 106.7009,
        'coordinates': [
          [10.7760, 106.7000],
          [10.7770, 106.7010],
          [10.7780, 106.7020],
        ],
      };

      final cell = ReportDensityCell.fromJson(json);

      expect(cell.cellId, equals('8b2f567406a0fff'));
      expect(cell.count, equals(2));
      expect(cell.level, equals(DensityLevel.low));
      expect(cell.color, equals(const Color(0xFF22C55E)));
      expect(cell.latitude, closeTo(10.7769, 0.0001));
      expect(cell.longitude, closeTo(106.7009, 0.0001));
      expect(cell.coordinates.length, equals(3));
    });

    test('ReportDensityCell parses MEDIUM and HIGH levels correctly', () {
      final mediumJson = {
        'cellId': 'cell_medium',
        'count': 4,
        'level': 'MEDIUM',
        'color': '#F59E0B',
        'latitude': 10.0,
        'longitude': 106.0,
        'coordinates': [],
      };
      final mediumCell = ReportDensityCell.fromJson(mediumJson);
      expect(mediumCell.level, equals(DensityLevel.medium));
      expect(mediumCell.color, equals(const Color(0xFFF59E0B)));

      final highJson = {
        'cellId': 'cell_high',
        'count': 7,
        'level': 'HIGH',
        'color': '#EF4444',
        'latitude': 10.0,
        'longitude': 106.0,
        'coordinates': [],
      };
      final highCell = ReportDensityCell.fromJson(highJson);
      expect(highCell.level, equals(DensityLevel.high));
      expect(highCell.color, equals(const Color(0xFFEF4444)));
    });

    test('ReportDensityResult parses GeoJSON FeatureCollection correctly', () {
      final json = {
        'resolution': 11,
        'zoom': 14.5,
        'totalCells': 1,
        'truncated': false,
        'cells': [
          {
            'cellId': 'cell_1',
            'count': 3,
            'level': 'MEDIUM',
            'color': '#F59E0B',
            'latitude': 10.8,
            'longitude': 106.7,
            'coordinates': [],
          }
        ],
        'geojson': {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'cellId': 'cell_1', 'count': 3},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [106.7, 10.8],
                    [106.71, 10.81],
                    [106.7, 10.8],
                  ]
                ]
              }
            }
          ]
        }
      };

      final result = ReportDensityResult.fromJson(json);

      expect(result.resolution, equals(11));
      expect(result.zoom, closeTo(14.5, 0.01));
      expect(result.totalCells, equals(1));
      expect(result.truncated, isFalse);
      expect(result.cells.length, equals(1));
      expect(result.geojson['type'], equals('FeatureCollection'));
      expect(result.geojsonString, contains('FeatureCollection'));
    });
  });
}

