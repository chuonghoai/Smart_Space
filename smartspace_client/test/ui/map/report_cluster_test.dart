import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/ui/components/map_cluster_sheet.dart';
import 'package:smartspace_client/ui/mobile/map/map_controller.dart';
import 'package:smartspace_client/ui/mobile/map/report_cluster_layer.dart';

ReportModel _report(
  String id, {
  EReportSeverity? severity,
  double lat = 10.8,
  double lng = 106.7,
  DateTime? createdAt,
}) =>
    ReportModel(
      id: id,
      title: id,
      description: '',
      imageUrl: '',
      latitude: lat,
      longitude: lng,
      status: ReportStatus.pending,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      severity: severity,
    );

void main() {
  group('ReportClusterLayer.toFeatureCollection', () {
    test('tạo Point [lng, lat] kèm id, isDangerous, imageKey, fallbackKey', () {
      final json = jsonDecode(ReportClusterLayer.toFeatureCollection(
        [_report('a', severity: EReportSeverity.critical, lat: 10.5, lng: 106.5)],
        (r) => 'img-${r.id}',
        (r) => r.isDangerous ? 'fallback-d' : 'fallback-n',
      )) as Map<String, dynamic>;

      expect(json['type'], 'FeatureCollection');
      final feature = (json['features'] as List).single as Map<String, dynamic>;
      expect(feature['geometry'], {
        'type': 'Point',
        'coordinates': [106.5, 10.5],
      });
      expect(feature['properties'], {
        'id': 'a',
        'isDangerous': true,
        'imageKey': 'img-a',
        'fallbackKey': 'fallback-d',
      });
    });

    test('bỏ report có toạ độ (0,0)', () {
      final json = jsonDecode(ReportClusterLayer.toFeatureCollection(
        [_report('a'), _report('zero', lat: 0, lng: 0)],
        (r) => r.id,
        (r) => 'fallback',
      )) as Map<String, dynamic>;
      expect((json['features'] as List), hasLength(1));
    });
  });

  test('MapClusterSheet.sortForCluster: nguy hiểm nhất trước, rồi mới nhất trước', () {
    final sorted = MapClusterSheet.sortForCluster([
      _report('low', severity: EReportSeverity.low),
      _report('none'),
      _report('high-old', severity: EReportSeverity.high, createdAt: DateTime(2026, 1, 1)),
      _report('high-new', severity: EReportSeverity.high, createdAt: DateTime(2026, 2, 1)),
      _report('critical', severity: EReportSeverity.critical),
    ]);
    expect(sorted.map((r) => r.id), ['critical', 'high-new', 'high-old', 'low', 'none']);
  });

  test('MapState.getFilteredReports: 2 nhóm Nguy hiểm / Thông thường không chồng nhau', () {
    final reports = [
      _report('danger', severity: EReportSeverity.high),
      _report('normal', severity: EReportSeverity.medium),
      _report('unrated'),
    ];

    expect(
      const MapState().getFilteredReports(reports).map((r) => r.id),
      ['danger', 'normal', 'unrated'],
    );
    expect(
      const MapState(showNormal: false).getFilteredReports(reports).map((r) => r.id),
      ['danger'],
    );
    expect(
      const MapState(showDangerous: false).getFilteredReports(reports).map((r) => r.id),
      ['normal', 'unrated'],
    );
  });
}
