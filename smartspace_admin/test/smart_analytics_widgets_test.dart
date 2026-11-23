import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/home/models/admin_overview_model.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/spatial_analytics_model.dart';
import 'package:smartspace_admin/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_admin/features/reports/models/report_trend_model.dart';
import 'package:smartspace_admin/features/reports/models/staff_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/smart_alerts_section.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/spatial_hotspot_panel.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_workload_badge.dart';

void main() {
  group('Smart Analytics DTO parsing', () {
    test('AdminOverviewModel parses volumeSpike, SLA at-risk, and 7d pulse', () {
      final model = AdminOverviewModel.fromJson({
        'userCount': 120,
        'staffCount': 8,
        'adminCount': 2,
        'issueCount': 15,
        'pendingCount': 6,
        'processingCount': 9,
        'atRiskCount': 4,
        'pendingAtRiskCount': 2,
        'processingAtRiskCount': 2,
        'overloadedStaffCount': 1,
        'pendingOver24hCount': 3,
        'volumeSpike': {
          'isSpike': true,
          'insufficientData': false,
          'todayCount': 12,
          'baselineAvg14d': 3.5,
          'baselineStdDev14d': 1.2,
          'zScore': 3.1,
          'activeDays': 14,
        },
        'pulse7Days': [
          {'date': '17/11', 'inflow': 4, 'outflow': 3},
          {'date': '18/11', 'inflow': 6, 'outflow': 5},
        ],
      });

      expect(model.atRiskCount, 4);
      expect(model.overloadedStaffCount, 1);
      expect(model.volumeSpike?.isSpike, isTrue);
      expect(model.volumeSpike?.zScore, 3.1);
      expect(model.pulse7Days.length, 2);
      expect(model.pulse7Days.first.inflow, 4);
    });

    test('ReportTrendData & ReportStatisticsModel parse new analytics fields', () {
      final trend = ReportTrendData.fromJson({
        'baselineAvg14d': 4.2,
        'anomalyCount': 1,
        'insufficientData': false,
        'items': [
          {'label': '20/11', 'count': 4, 'anomaly': false, 'baselineAvg': 4.0},
          {'label': '21/11', 'count': 11, 'anomaly': true, 'baselineAvg': 4.1},
        ],
      });
      expect(trend.anomalyCount, 1);
      expect(trend.items.last.anomaly, isTrue);
      expect(trend.items.first.baselineAvg, 4.0);

      final stats = ReportStatisticsModel.fromJson({
        'total': 20,
        'byStatus': {'pending': 5},
        'bySeverity': {'high': 4},
        'atRiskCount': 3,
        'bottleneckCount': 2,
        'p90MinutesBySeverity': {'high': 1440},
        'p90InsufficientSamples': {'high': false, 'low': true},
      });
      expect(stats.atRiskCount, 3);
      expect(stats.bottleneckCount, 2);
      expect(stats.p90MinutesBySeverity['high'], 1440);
      expect(stats.p90InsufficientSamples['low'], isTrue);
    });

    test('StaffModel & SpatialAnalyticsResult parse weighted workload and hotspots', () {
      final staff = StaffModel.fromJson({
        'id': 's1',
        'fullName': 'Nguyen Van A',
        'email': 'a@ute.edu.vn',
        'processingCount': 3,
        'weightedLoad': 11,
        'overdueCount': 1,
        'isOverloaded': true,
        'assignmentHint': 'overloaded',
        'severityBreakdown': {'low': 1, 'critical': 2},
      });
      expect(staff.weightedLoad, 11);
      expect(staff.isOverloaded, isTrue);
      expect(staff.assignmentHint, 'overloaded');
      expect(staff.severityBreakdown['critical'], 2);

      final spatial = SpatialAnalyticsResult.fromJson({
        'h3Resolution': 11,
        'totalHotspots': 1,
        'acceleratingHotspots': 1,
        'hotspots': [
          {
            'h3Index': '8b65a1a2b3c4fff',
            'centerLat': 10.85,
            'centerLng': 106.77,
            'sampleAddress': 'Khu A',
            'countLast30d': 8,
            'prev90dAvg30d': 2.0,
            'growthRatio': 4.0,
            'isAccelerating': true,
            'pendingCount': 3,
            'processingCount': 2,
            'highCriticalCount': 4,
            'overdueCount': 1,
            'riskScore': 22,
          },
        ],
      });
      expect(spatial.acceleratingHotspots, 1);
      expect(spatial.hotspots.first.isAccelerating, isTrue);
      expect(spatial.hotspots.first.riskScore, 22);
    });
  });

  group('Smart Analytics widgets Light/Dark & L10n rendering', () {
    Widget wrapWithTheme({
      required Widget child,
      required Brightness brightness,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('SmartAlertsSection renders alerts & pulse in Light & Dark modes',
        (tester) async {
      const overview = AdminOverviewModel(
        userCount: 50,
        staffCount: 6,
        adminCount: 1,
        issueCount: 10,
        atRiskCount: 3,
        pendingAtRiskCount: 1,
        processingAtRiskCount: 2,
        overloadedStaffCount: 1,
        pendingOver24hCount: 2,
        volumeSpike: VolumeSpikeAlert(
          isSpike: true,
          insufficientData: false,
          todayCount: 11,
          baselineAvg14d: 3.0,
          baselineStdDev14d: 1.0,
          zScore: 2.5,
          activeDays: 12,
        ),
        pulse7Days: [
          DailyPulseItem(date: '22/11', inflow: 5, outflow: 3),
          DailyPulseItem(date: '23/11', inflow: 11, outflow: 4),
        ],
      );

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          wrapWithTheme(
            brightness: brightness,
            child: const SmartAlertsSection(
              overview: overview,
              isDesktop: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cảnh báo vận hành & Nhịp độ 7 ngày'), findsOneWidget);
        expect(find.text('Phản ánh tăng đột biến hôm nay'), findsOneWidget);
        expect(find.text('Cảnh báo sắp chạm hạn SLA'), findsOneWidget);
        expect(find.text('Nhân sự quá tải công việc'), findsOneWidget);
      }
    });

    testWidgets('StaffWorkloadBadge & SpatialHotspotPanel render cleanly',
        (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          brightness: Brightness.dark,
          overrides: [
            spatialAnalyticsProvider.overrideWith(
              (ref) async => const SpatialAnalyticsResult(
                totalHotspots: 1,
                acceleratingHotspots: 1,
                hotspots: [
                  SpatialHotspotItem(
                    h3Index: '8b65a1a2b3c4fff',
                    centerLat: 10.85,
                    centerLng: 106.77,
                    sampleAddress: 'Toa A',
                    countLast30d: 7,
                    prev90dAvg30d: 1.5,
                    isAccelerating: true,
                    pendingCount: 2,
                    riskScore: 14,
                  ),
                ],
              ),
            ),
          ],
          child: Column(
            children: [
              const StaffWorkloadBadge(
                weightedLoad: 8,
                processingCount: 3,
                isOverloaded: true,
                assignmentHint: 'overloaded',
                severityBreakdown: {'critical': 1, 'high': 1, 'low': 1},
                showAssignmentHint: true,
              ),
              SpatialHotspotPanel(onHotspotTap: (_) {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8đ tải (3 việc)'), findsOneWidget);
      expect(find.text('Quá tải'), findsOneWidget);
      expect(find.text('Toa A'), findsOneWidget);
      expect(find.text('Tăng tốc'), findsOneWidget);
    });
  });
}
