import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_detail_model.dart';
import 'package:smartspace_admin/features/reports/models/report_list_model.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/reports/admin_report_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_dashboard_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';

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

      final processedLate = ReportListItem.fromJson({
        'id': '2b',
        'title': 'Done late',
        'status': 'processed',
        'deadline': past.toIso8601String(),
        'resolved_at': DateTime.now().toIso8601String(),
      });
      expect(processedLate.isOverdue, isTrue);

      final recentFuture = RecentReportModel.fromJson({
        'id': '3',
        'title': 'Upcoming',
        'status': 'pending',
        'deadline': future.toIso8601String(),
      });
      expect(recentFuture.deadlineDate, isNotNull);
      expect(recentFuture.isOverdueActive, isFalse);
      expect(recentFuture.remainingDays, greaterThanOrEqualTo(1));
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
            efficiencyRate: 0.0,
          ),
          StaffDeadlinePerformanceItem(
            staff: staff('s2', 'Trần Đúng Hạn'),
            overdueCount: 0,
            completedLateCount: 0,
            completedOnTimeCount: 2,
            hasMissedDeadline: false,
            efficiencyRate: 100.0,
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
      expect(find.text('Xuất sắc'), findsOneWidget);
      expect(find.text('Hiệu suất công việc: 100%'), findsOneWidget);
      expect(find.text('Hiệu suất công việc: 0%'), findsOneWidget);
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
            efficiencyRate: 100.0,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(stats, theme: AppTheme.darkTheme, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Deadline Performance'), findsOneWidget);
      expect(find.text('No staff members have missed a deadline'), findsOneWidget);
      expect(find.text('100% on time'), findsOneWidget);
      expect(find.text('Alex Timely'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('Work efficiency: 100%'), findsOneWidget);
    });
  });

  group('RejectReportDialog & StaffDetailSheetBody Tests', () {
    testWidgets('RejectReportDialog confirms cleanly without _dependents.isEmpty crash',
        (tester) async {
      String? capturedReason;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  capturedReason = await showDialog<String>(
                    context: context,
                    builder: (_) => const RejectReportDialog(),
                  );
                },
                child: const Text('Open Reject'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reject'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Không hợp lệ');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(capturedReason, 'Không hợp lệ');
    });

    testWidgets('StaffDetailSheetBody shows monthly workload breakdown',
        (tester) async {
      final staffMember = StaffModel(
        id: 'staff-1',
        email: 'nv@test.com',
        fullName: 'Nhân viên Kiểm thử',
        status: 'active',
        processingCount: 2,
      );
      final stats = StaffStatisticsModel(
        totalStaff: 1,
        activeStaff: 1,
        blockedStaff: 0,
        processingReports: 2,
        resolved: 3,
        resolvedPrevious: 1,
        workload: const [],
        selectedYear: 2026,
        selectedMonth: 5,
        deadlinePerformance: [
          StaffDeadlinePerformanceItem(
            staff: staffMember,
            overdueCount: 1,
            completedLateCount: 0,
            completedOnTimeCount: 3,
            hasMissedDeadline: true,
            processingCount: 2,
            resolvedCount: 3,
            rehandlingCount: 1,
            totalTasks: 5,
            efficiencyRate: 75.0,
          ),
        ],
      );

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffStatisticsProvider.overrideWith((ref) async => stats),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                theme: AppTheme.darkTheme,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('vi'),
                home: Builder(
                  builder: (ctx) => Scaffold(
                    body: StaffDetailSheetBody(
                      staff: staffMember,
                      parentContext: ctx,
                      sheetContext: ctx,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Khối lượng công việc trong tháng 05/2026'),
        findsOneWidget,
      );
      expect(
        find.text('2 đang xử lý, 3 đã xử lý, 1 trễ hạn, 1 xử lý lại'),
        findsOneWidget,
      );
      expect(find.text('Hiệu suất công việc: 75%'), findsOneWidget);
      expect(find.text('Xem phản ánh được giao'), findsOneWidget);
      expect(container.read(reportFilterProvider).assigneeId, isNull);
    });
  });
}
