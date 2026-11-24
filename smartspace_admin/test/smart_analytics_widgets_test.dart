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
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_list_response.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart' as staff_mgmt;
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/features/staff/models/staff_summary_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/mobile/staff/mobile_staff_view.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/overloaded_staff_modal.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/smart_alerts_section.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/spatial_hotspot_panel.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_workload_badge.dart';
import 'package:smartspace_admin/ui/shared/dashboard/analytics_guide_modal.dart';
import 'package:smartspace_admin/ui/shared/dashboard/stat_card_grid.dart';

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
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    testWidgets('StatCardGrid keeps all cards equal width on orphan last row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 1140,
              child: StatCardGrid(
                crossAxisCount: 6,
                itemHeight: 84,
                itemCount: 7,
                itemBuilder: (_, index, _) => Card(
                  key: Key('stat_card_$index'),
                  child: Text('Card $index'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstWidth = tester.getSize(find.byKey(const Key('stat_card_0'))).width;
      final lastWidth = tester.getSize(find.byKey(const Key('stat_card_6'))).width;
      expect(lastWidth, closeTo(firstWidth, 0.01));
    });

    testWidgets('OverloadedStaffModal & GuideModal & StaffDetailSheetBody render metrics',
        (tester) async {
      const staff = staff_mgmt.StaffModel(
        id: 's1',
        fullName: 'Nguyen Van Qua Tai',
        email: 'quatai@ute.edu.vn',
        status: 'active',
        processingCount: 4,
        weightedLoad: 12,
        overdueCount: 2,
        isOverloaded: true,
        severityBreakdown: {'critical': 1, 'high': 2, 'medium': 0, 'low': 1},
      );
      final stats = StaffStatisticsModel(
        totalStaff: 5,
        activeStaff: 5,
        blockedStaff: 0,
        processingReports: 8,
        resolved: 10,
        resolvedPrevious: 8,
        workload: const [],
        teamAvgWeightedLoad: 4.0,
        overloadedStaffCount: 1,
        bottleneckCount: 1,
        deadlinePerformance: const [
          StaffDeadlinePerformanceItem(
            staff: staff,
            overdueCount: 2,
            completedLateCount: 0,
            completedOnTimeCount: 5,
            hasMissedDeadline: true,
            processingCount: 4,
            resolvedCount: 5,
            weightedLoad: 12,
            bottleneckCount: 1,
            isOverloaded: true,
            efficiencyRate: 71.4,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithTheme(
          brightness: Brightness.light,
          overrides: [
            staffStatisticsProvider.overrideWith((ref) async => stats),
          ],
          child: Builder(
            builder: (ctx) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => showOverloadedStaffModal(ctx),
                  child: const Text('Open Overload'),
                ),
                ElevatedButton(
                  onPressed: () => showAnalyticsGuideModal(
                    ctx,
                    title: 'Guide Title',
                    whatLabel: 'Là gì',
                    purposeLabel: 'Tác dụng',
                    tellsLabel: 'Cho biết',
                    sections: const [
                      AnalyticsGuideSection(
                        title: 'P90',
                        whatItIs: 'Mốc 90%',
                        purpose: 'Tìm ca chậm',
                        whatItTells: 'Cần hỗ trợ',
                      ),
                    ],
                  ),
                  child: const Text('Open Guide'),
                ),
                StaffDetailSheetBody(
                  staff: staff,
                  parentContext: ctx,
                  sheetContext: ctx,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // StaffDetailSheetBody shows overload status & comparison
      expect(find.text('Tình trạng tải trọng công việc'), findsOneWidget);
      expect(find.text('12đ tải quy đổi (TB đội ngũ: 4đ)'), findsOneWidget);

      // Open OverloadedStaffModal
      await tester.tap(find.text('Open Overload'));
      await tester.pumpAndSettle();
      expect(find.text('Nhân sự đang quá tải công việc'), findsOneWidget);
      expect(find.text('Nguyen Van Qua Tai'), findsWidgets);
    });

    testWidgets('MobileStaffView shows detailed statistics expanded by default',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffListProvider.overrideWith(() => _MockStaffListNotifier()),
            staffStatisticsProvider.overrideWith(
              (ref) async => const StaffStatisticsModel(
                totalStaff: 2,
                activeStaff: 2,
                blockedStaff: 0,
                processingReports: 1,
                resolved: 2,
                resolvedPrevious: 1,
                workload: [],
              ),
            ),
            staffTrendProvider.overrideWith((ref, arg) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const Scaffold(body: MobileStaffView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Luồng xử lý'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });
  });
}

class _MockStaffListNotifier extends StaffListNotifier {
  @override
  Future<StaffListResponse> build() async => const StaffListResponse(
        summary: StaffSummaryModel(total: 0, active: 0, blocked: 0, totalProcessing: 0),
        staffs: [],
        currentPage: 1,
        pageSize: 10,
        totalPages: 1,
        totalElements: 0,
      );
}
