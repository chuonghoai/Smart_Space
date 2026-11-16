import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/reports/models/report_detail_model.dart';
import 'package:smartspace_admin/features/reports/models/report_list_model.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_dashboard_widgets.dart';

void main() {
  group('Deadline & Reject Model Parsing', () {
    test('ReportDetailModel parses deadline, rejectedReason, rejectedAt', () {
      final model = ReportDetailModel.fromJson({
        'id': 'r1',
        'title': 'Test report',
        'description': 'Desc',
        'status': 'REJECTED',
        'severity': 'high',
        'is_anonymous': false,
        'created_at': '2026-05-01T10:00:00',
        'deadline': '2026-05-08T10:00:00',
        'rejected_reason': 'Duplicate issue',
        'rejected_at': '2026-05-02T12:00:00',
      });
      expect(model.deadline, DateTime.parse('2026-05-08T10:00:00'));
      expect(model.rejectedReason, 'Duplicate issue');
      expect(model.rejectedAt, DateTime.parse('2026-05-02T12:00:00'));
    });

    test('ReportListItem & RecentReportModel detect overdue active reports', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final future = DateTime.now().add(const Duration(days: 2));

      final overdueItem = ReportListItem.fromJson({
        'id': '1',
        'title': 'Overdue',
        'status': 'processing',
        'deadline': past.toIso8601String(),
      });
      expect(overdueItem.isOverdueActive, isTrue);

      final processedPast = ReportListItem.fromJson({
        'id': '2',
        'title': 'Done',
        'status': 'processed',
        'deadline': past.toIso8601String(),
      });
      expect(processedPast.isOverdueActive, isFalse);

      final recentFuture = RecentReportModel.fromJson({
        'id': '3',
        'title': 'Upcoming',
        'status': 'pending',
        'deadline': future.toIso8601String(),
      });
      expect(recentFuture.deadlineDate, isNotNull);
      expect(recentFuture.isOverdueActive, isFalse);
    });
  });

  group('StaffDeadlinePerformanceCard Widget Tests', () {
    StaffModel staff(String id, String name) => StaffModel(
          id: id,
          email: '$id@test.com',
          fullName: name,
          status: 'active',
        );

    Widget buildWidget(StaffStatisticsModel stats, {ThemeData? theme, Locale locale = const Locale('vi')}) {
      return ProviderScope(
        overrides: [
          staffStatisticsProvider.overrideWith((ref) async => stats),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: StaffDeadlinePerformanceCard(),
            ),
          ),
        ),
      );
    }

    testWidgets('shows missed deadline summary and staff row in Light Mode (VI)', (tester) async {
      final stats = StaffStatisticsModel(
        totalStaff: 2,
        activeStaff: 2,
        blockedStaff: 0,
        processingReports: 1,
        resolved: 2,
        resolvedPrevious: 1,
        workload: const [],
        anyStaffMissedDeadline: true,
        overdueReports: 1,
        completedOnTime: 2,
        completedLate: 1,
        onTimeRate: 66.7,
        deadlinePerformance: [
          StaffDeadlinePerformanceItem(
            staff: staff('s1', 'Nguyễn Văn Trễ'),
            overdueCount: 1,
            completedLateCount: 1,
            completedOnTimeCount: 0,
            hasMissedDeadline: true,
          ),
          StaffDeadlinePerformanceItem(
            staff: staff('s2', 'Trần Đúng Hạn'),
            overdueCount: 0,
            completedLateCount: 0,
            completedOnTimeCount: 2,
            hasMissedDeadline: false,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(stats, theme: AppTheme.lightTheme));
      await tester.pumpAndSettle();

      expect(find.text('Hiệu suất theo hạn xử lý'), findsOneWidget);
      expect(find.text('1 đang quá hạn · 1 hoàn thành trễ'), findsOneWidget);
      expect(find.text('Nguyễn Văn Trễ'), findsOneWidget);
      expect(find.text('Trần Đúng Hạn'), findsOneWidget);
      expect(find.text('Trễ hạn'), findsOneWidget);
      expect(find.text('Đúng hạn'), findsOneWidget);
    });

    testWidgets('shows no missed deadline banner in Dark Mode (EN)', (tester) async {
      final stats = StaffStatisticsModel(
        totalStaff: 1,
        activeStaff: 1,
        blockedStaff: 0,
        processingReports: 0,
        resolved: 3,
        resolvedPrevious: 2,
        workload: const [],
        anyStaffMissedDeadline: false,
        overdueReports: 0,
        completedOnTime: 3,
        completedLate: 0,
        onTimeRate: 100.0,
        deadlinePerformance: [
          StaffDeadlinePerformanceItem(
            staff: staff('s1', 'Alex Timely'),
            overdueCount: 0,
            completedLateCount: 0,
            completedOnTimeCount: 3,
            hasMissedDeadline: false,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(stats, theme: AppTheme.darkTheme, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Deadline Performance'), findsOneWidget);
      expect(find.text('No staff members have missed a deadline'), findsOneWidget);
      expect(find.text('100% on time'), findsOneWidget);
      expect(find.text('Alex Timely'), findsOneWidget);
    });
  });
}
