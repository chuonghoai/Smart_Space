import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';

// MapBounds được test trong mobile_shared/test/features/map/map_viewport_test.dart
void main() {
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
