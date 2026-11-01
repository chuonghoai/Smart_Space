import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/report_density_model.dart';
import 'package:smartspace_admin/features/map/models/report_timeframe.dart';
import 'package:smartspace_admin/features/map/services/map_service.dart';

class _FakeMapDensityService extends MapService {
  int callCount = 0;
  String? lastTimeframe;

  @override
  Future<ApiResponse<ReportDensityResult>> getReportDensity({
    required double north,
    required double south,
    required double east,
    required double west,
    double zoom = 14.0,
    String? timeframe,
  }) async {
    callCount++;
    lastTimeframe = timeframe;
    return ApiResponse(
      success: true,
      message: 'OK',
      data: ReportDensityResult(
        resolution: 11,
        zoom: zoom,
        totalCells: 1,
        truncated: false,
        cells: const [
          ReportDensityCell(
            cellId: '8b30e02844d0fff',
            count: 5,
            level: DensityLevel.medium,
            color: Color(0xFFF59E0B),
            latitude: 10.8231,
            longitude: 106.6297,
            coordinates: [
              [10.823, 106.629],
              [10.824, 106.630],
            ],
          ),
        ],
        geojson: {
          'type': 'FeatureCollection',
          'features': [],
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'map_show_density': jsonEncode(true),
      'map_report_timeframe': jsonEncode('3m'),
    });
  });

  group('ReportDensityCell', () {
    test('fromJson correctly parses LOW level', () {
      final json = {
        'cellId': 'cell_1',
        'count': 2,
        'level': 'LOW',
        'color': '#22C55E',
        'latitude': 10.8,
        'longitude': 106.6,
        'coordinates': [
          [10.8, 106.6],
          [10.81, 106.61],
        ],
      };
      final cell = ReportDensityCell.fromJson(json);
      expect(cell.cellId, 'cell_1');
      expect(cell.count, 2);
      expect(cell.level, DensityLevel.low);
      expect(cell.color, const Color(0xFF22C55E));
      expect(cell.coordinates.length, 2);
    });

    test('fromJson correctly parses HIGH level', () {
      final json = {
        'cellId': 'cell_2',
        'count': 10,
        'level': 'HIGH',
        'color': '#EF4444',
        'latitude': 10.8,
        'longitude': 106.6,
        'coordinates': [],
      };
      final cell = ReportDensityCell.fromJson(json);
      expect(cell.level, DensityLevel.high);
      expect(cell.color, const Color(0xFFEF4444));
    });
  });

  group('ReportDensityResult', () {
    test('fromJson parses geojson and cells', () {
      final json = {
        'resolution': 11,
        'zoom': 14.5,
        'totalCells': 1,
        'truncated': false,
        'cells': [
          {
            'cellId': 'c1',
            'count': 1,
            'level': 'LOW',
            'color': '#22C55E',
            'latitude': 10.0,
            'longitude': 106.0,
            'coordinates': [],
          }
        ],
        'geojson': {'type': 'FeatureCollection', 'features': []},
      };
      final result = ReportDensityResult.fromJson(json);
      expect(result.resolution, 11);
      expect(result.zoom, 14.5);
      expect(result.cells.length, 1);
      expect(result.geojsonString, isNotNull);
      expect(jsonDecode(result.geojsonString!)['type'], 'FeatureCollection');
    });
  });

  group('ReportTimeframe', () {
    test('fromCode maps codes correctly', () {
      expect(ReportTimeframe.fromCode('1m'), ReportTimeframe.month1);
      expect(ReportTimeframe.fromCode('3m'), ReportTimeframe.month3);
      expect(ReportTimeframe.fromCode('6m'), ReportTimeframe.month6);
      expect(ReportTimeframe.fromCode('9m'), ReportTimeframe.month9);
      expect(ReportTimeframe.fromCode('12m'), ReportTimeframe.month12);
      expect(ReportTimeframe.fromCode('all'), ReportTimeframe.all);
      expect(ReportTimeframe.fromCode(null), ReportTimeframe.all);
      expect(ReportTimeframe.fromCode('unknown'), ReportTimeframe.all);
    });
  });

  group('AdminReportDensityNotifier', () {
    const viewport = MapBounds(minLat: 10.7, maxLat: 10.9, minLng: 106.6, maxLng: 106.8);

    test('loads preferences on creation and loads for viewport', () async {
      final fakeService = _FakeMapDensityService();
      final notifier = AdminReportDensityNotifier(fakeService);

      // Wait for _loadPreference to complete
      await pumpEventQueue();

      expect(notifier.state.isEnabled, isTrue);
      expect(notifier.state.timeframe, ReportTimeframe.month3);

      await notifier.loadForViewport(viewport, 14.0, force: true);
      expect(fakeService.callCount, 1);
      expect(fakeService.lastTimeframe, '3m');
      expect(notifier.state.cells.length, 1);
      expect(notifier.state.cells.first.cellId, '8b30e02844d0fff');

      // Test changing timeframe
      await notifier.setTimeframe(ReportTimeframe.month6);
      expect(notifier.state.timeframe, ReportTimeframe.month6);
      expect(fakeService.callCount, 2);
      expect(fakeService.lastTimeframe, '6m');

      // Test disabling density
      await notifier.toggleEnabled();
      expect(notifier.state.isEnabled, isFalse);
      expect(notifier.state.cells, isEmpty);
      expect(notifier.state.geojsonString, isNull);
    });
  });
}
