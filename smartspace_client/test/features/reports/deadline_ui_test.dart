import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:mobile_shared/core/utils/report_deadline_helper.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/widgets/my_report_card.dart';

void main() {
  group('ReportDeadlineHelper lifecycle transitions', () {
    // Test Case ID: SMP-005
    // Description: Kiểm tra ReportDeadlineHelper.isOverdue qua các mốc trạng thái: quá hạn đang xử lý, hoàn thành trễ, mở lại với hạn mới và quá hạn lại.
    test('handles overdue processing, late processed, reopened future deadline, and re-overdue', () {
      final now = DateTime(2026, 11, 16, 12, 0);
      final pastDeadline = DateTime(2026, 11, 10, 12, 0);
      final futureReopenDeadline = DateTime(2026, 11, 21, 12, 0);

      // 1. Processing past deadline -> overdue
      expect(
        ReportDeadlineHelper.isOverdue(
          status: 'processing',
          deadline: pastDeadline,
          now: now,
        ),
        isTrue,
      );

      // 2. Processed after deadline -> retains overdue
      expect(
        ReportDeadlineHelper.isOverdue(
          status: 'processed',
          deadline: pastDeadline,
          resolvedAt: DateTime(2026, 11, 12, 9, 0),
          now: now,
        ),
        isTrue,
      );

      // 3. Reopened with updated future deadline -> overdue cleared even if old resolvedAt exists
      expect(
        ReportDeadlineHelper.isOverdue(
          status: 'processing',
          deadline: futureReopenDeadline,
          resolvedAt: DateTime(2026, 11, 12, 9, 0),
          now: now,
        ),
        isFalse,
      );

      // 4. After passing new reopen deadline -> overdue again
      expect(
        ReportDeadlineHelper.isOverdue(
          status: 'processing',
          deadline: futureReopenDeadline,
          resolvedAt: DateTime(2026, 11, 12, 9, 0),
          now: DateTime(2026, 11, 22, 9, 0),
        ),
        isTrue,
      );
    });
  });

  group('MyReportCard deadline visibility (Light & Dark)', () {
    Widget wrap(Widget child, ThemeData theme) {
      return MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
    }

    // Test Case ID: SMP-006
    // Description: Kiểm tra MyReportCard ở Light Mode hiển thị dòng "Hạn xử lý:", số ngày còn lại và không hiện nhãn "Quá hạn" khi chưa đến hạn.
    testWidgets('shows deadline note with remaining days when active (Light Mode)', (tester) async {
      final now = DateTime.now();
      final report = ReportModel(
        id: 'c1',
        title: 'Đèn đường tắt',
        description: 'Khu vực cổng sau',
        imageUrl: '',
        latitude: 10.8,
        longitude: 106.7,
        status: ReportStatus.processing,
        createdAt: now.subtract(const Duration(days: 1)),
        deadline: now.add(const Duration(days: 3, hours: 1)),
      );

      await tester.pumpWidget(wrap(MyReportCard(report: report), AppTheme.lightTheme));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hạn xử lý:'), findsOneWidget);
      expect(find.textContaining('Còn '), findsOneWidget);
      expect(find.text('Quá hạn'), findsNothing);
    });

    // Test Case ID: SMP-007
    // Description: Kiểm tra MyReportCard ở Dark Mode hiển thị hạn xử lý, nhãn "Quá hạn" và "Xử lý chưa thỏa đáng" khi xử lý trễ và review chưa đạt.
    testWidgets('shows deadline note and Overdue badge when completed late (Dark Mode)', (tester) async {
      final pastDeadline = DateTime(2026, 10, 10, 14, 0);
      final report = ReportModel(
        id: 'c2',
        title: 'Nước rò rỉ hành lang',
        description: 'Tầng 2 khu A',
        imageUrl: '',
        latitude: 10.8,
        longitude: 106.7,
        status: ReportStatus.processed,
        isReviewResolved: false,
        createdAt: DateTime(2026, 10, 5, 10, 0),
        deadline: pastDeadline,
        resolvedAt: DateTime(2026, 10, 12, 16, 0),
      );

      await tester.pumpWidget(wrap(MyReportCard(report: report), AppTheme.darkTheme));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hạn xử lý:'), findsOneWidget);
      expect(find.text('Quá hạn'), findsOneWidget);
      expect(find.text('Xử lý chưa thỏa đáng'), findsOneWidget);
    });
  });
}
