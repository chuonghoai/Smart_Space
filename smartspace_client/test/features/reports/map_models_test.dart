import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';

void main() {
  group('MapBounds', () {
    const bounds = MapBounds(minLat: 10, maxLat: 11, minLng: 106, maxLng: 107);

    test('contains: khung con nằm trọn bên trong', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.2, maxLat: 10.8, minLng: 106.1, maxLng: 106.9)),
        isTrue,
      );
      expect(bounds.contains(bounds), isTrue);
    });

    test('contains: khung lệch ra ngoài một cạnh', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.5, maxLat: 11.1, minLng: 106.1, maxLng: 106.9)),
        isFalse,
      );
    });

    test('expandBy: giữ tâm, nhân kích thước theo factor', () {
      final expanded = bounds.expandBy(2);
      expect(expanded.minLat, closeTo(9.5, 1e-9));
      expect(expanded.maxLat, closeTo(11.5, 1e-9));
      expect(expanded.minLng, closeTo(105.5, 1e-9));
      expect(expanded.maxLng, closeTo(107.5, 1e-9));
      expect(expanded.contains(bounds), isTrue);
    });

    test('expandBy: kẹp trong giới hạn toạ độ hợp lệ', () {
      const world = MapBounds(minLat: -80, maxLat: 80, minLng: -170, maxLng: 170);
      final expanded = world.expandBy(3);
      expect(expanded.minLat, -90);
      expect(expanded.maxLat, 90);
      expect(expanded.minLng, -180);
      expect(expanded.maxLng, 180);
    });

    test('toQueryParameters dùng đúng tên param của backend', () {
      expect(bounds.toQueryParameters(), {
        'min_lat': 10.0,
        'max_lat': 11.0,
        'min_lng': 106.0,
        'max_lng': 107.0,
      });
    });
  });

  group('ReportModel.severity', () {
    Map<String, dynamic> json(String? severity) => {
          'id': 'r1',
          'title': 't',
          'status': 'pending',
          'latitude': 10.8,
          'longitude': 106.7,
          'severity': severity,
        };

    test('parse severity và isDangerous', () {
      expect(ReportModel.fromJson(json('critical')).isDangerous, isTrue);
      expect(ReportModel.fromJson(json('high')).isDangerous, isTrue);
      expect(ReportModel.fromJson(json('medium')).isDangerous, isFalse);
      expect(ReportModel.fromJson(json('low')).severity, EReportSeverity.low);
    });

    test('thiếu severity → null, không bị coi là nguy hiểm', () {
      final report = ReportModel.fromJson(json(null));
      expect(report.severity, isNull);
      expect(report.isDangerous, isFalse);
    });
  });

  group('MapReportsResult.fromJson', () {
    test('parse reports và truncated', () {
      final result = MapReportsResult.fromJson({
        'reports': [
          {'id': 'a', 'title': 'A', 'status': 'pending', 'latitude': 1, 'longitude': 2},
        ],
        'truncated': true,
      });
      expect(result.reports.single.id, 'a');
      expect(result.truncated, isTrue);
    });

    test('thiếu trường → mặc định rỗng và không truncated', () {
      final result = MapReportsResult.fromJson({});
      expect(result.reports, isEmpty);
      expect(result.truncated, isFalse);
    });
  });
}
