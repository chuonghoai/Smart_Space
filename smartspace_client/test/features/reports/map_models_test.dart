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

    // Test Case ID: SMP-008
    // Description: Kiểm tra parse severity từ JSON và xác định isDangerous cho critical, high, medium, low.
    test('parse severity và isDangerous', () {
      expect(ReportModel.fromJson(json('critical')).isDangerous, isTrue);
      expect(ReportModel.fromJson(json('high')).isDangerous, isTrue);
      expect(ReportModel.fromJson(json('medium')).isDangerous, isFalse);
      expect(ReportModel.fromJson(json('low')).severity, EReportSeverity.low);
    });

    // Test Case ID: SMP-009
    // Description: Kiểm tra ReportModel.fromJson khi severity là null thì severity null và isDangerous là false.
    test('thiếu severity → null, không bị coi là nguy hiểm', () {
      final report = ReportModel.fromJson(json(null));
      expect(report.severity, isNull);
      expect(report.isDangerous, isFalse);
    });
  });

  group('MapReportsResult.fromJson', () {
    // Test Case ID: SMP-010
    // Description: Kiểm tra MapReportsResult.fromJson parse đúng danh sách reports và cờ truncated.
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

    // Test Case ID: SMP-011
    // Description: Kiểm tra MapReportsResult.fromJson khi JSON rỗng trả về reports rỗng và truncated là false.
    test('thiếu trường → mặc định rỗng và không truncated', () {
      final result = MapReportsResult.fromJson({});
      expect(result.reports, isEmpty);
      expect(result.truncated, isFalse);
    });
  });
}
