import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/models/report_timeframe.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/components/map_controls.dart';
import 'package:smartspace_client/ui/components/map_density_legend.dart';
import 'package:smartspace_client/ui/components/map_settings_bottom_sheet.dart';
import 'package:smartspace_client/ui/components/report_info_sheet.dart';

Widget createLocalizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('vi'),
      Locale('en'),
    ],
    locale: const Locale('vi'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('Map Density UI Components Tests', () {
    testWidgets('MapDensityLegend renders correct elements', (tester) async {
      await tester.pumpWidget(createLocalizedApp(const MapDensityLegend()));
      await tester.pumpAndSettle();

      expect(find.byType(MapDensityLegend), findsOneWidget);
      expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
      expect(find.text('Mật độ phản ánh'), findsOneWidget);
      expect(find.text('1–2 phản ánh (Thấp)'), findsOneWidget);
      expect(find.text('3–5 phản ánh (Trung bình)'), findsOneWidget);
      expect(find.text('Trên 5 phản ánh (Cao)'), findsOneWidget);
    });

    testWidgets('MapSettingsBottomSheet renders, triggers toggle, and selects filter and timeframe', (tester) async {
      bool toggledValue = false;
      MapReportFilter selectedFilter = MapReportFilter.all;
      ReportTimeframe selectedTimeframe = ReportTimeframe.all;

      await tester.pumpWidget(
        createLocalizedApp(
          MapSettingsBottomSheet(
            isDensityEnabled: false,
            currentFilter: MapReportFilter.all,
            currentTimeframe: ReportTimeframe.all,
            onDensityToggle: (val) {
              toggledValue = val;
            },
            onFilterSelected: (filter) {
              selectedFilter = filter;
            },
            onTimeframeSelected: (tf) {
              selectedTimeframe = tf;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt bản đồ'), findsOneWidget);
      expect(find.text('Hiển thị mật độ phản ánh'), findsOneWidget);
      expect(find.text('Bộ lọc báo cáo'), findsOneWidget);
      expect(find.text('Khoảng thời gian'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Verify status filter chips exist
      expect(find.text('Tất cả'), findsNWidgets(2)); // Status 'Tất cả' and Timeframe 'Tất cả'
      expect(find.text('Phản ánh của tôi'), findsOneWidget);
      expect(find.text('Đang chờ'), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.text('Đã xử lý'), findsOneWidget);

      // Verify timeframe chips exist
      expect(find.text('1 tháng'), findsOneWidget);
      expect(find.text('3 tháng'), findsOneWidget);
      expect(find.text('6 tháng'), findsOneWidget);
      expect(find.text('9 tháng'), findsOneWidget);
      expect(find.text('12 tháng'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(toggledValue, isTrue);

      // Tap filter chip
      await tester.tap(find.text('Đang chờ'));
      await tester.pumpAndSettle();
      expect(selectedFilter, equals(MapReportFilter.pending));

      // Tap timeframe chip
      await tester.tap(find.text('3 tháng'));
      await tester.pumpAndSettle();
      expect(selectedTimeframe, equals(ReportTimeframe.month3));
    });

    testWidgets('MapControls includes settings button and fires callback', (tester) async {
      bool settingsClicked = false;

      await tester.pumpWidget(
        createLocalizedApp(
          Stack(
            children: [
              MapControls(
                showDangerous: true,
                showNormal: true,
                isDensityActive: true,
                onSettingsPressed: () {
                  settingsClicked = true;
                },
                onMyLocationPressed: () {},
                onFilterChanged: ({showDangerous, showNormal}) {},
                onRefreshPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pumpAndSettle();

      expect(settingsClicked, isTrue);
    });

    testWidgets('ReportInfoSheet renders and triggers onViewDetail when tapped', (tester) async {
      bool detailClicked = false;
      final report = ReportModel(
        id: 'test-report-123',
        title: 'Hố ga mất nắp',
        description: 'Đường Nguyễn Huệ hố ga nguy hiểm',
        imageUrl: '',
        latitude: 10.7769,
        longitude: 106.7009,
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        createLocalizedApp(
          ReportInfoSheet(
            report: report,
            onViewDetail: () {
              detailClicked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hố ga mất nắp'), findsOneWidget);
      expect(find.text('Đường Nguyễn Huệ hố ga nguy hiểm'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

      // Tap on the sheet
      await tester.tap(find.byType(ReportInfoSheet));
      await tester.pumpAndSettle();

      expect(detailClicked, isTrue);
    });
  });
}
