import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_client/features/reports/models/map_report_filter.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/components/map_controls.dart';
import 'package:smartspace_client/ui/components/map_density_legend.dart';
import 'package:smartspace_client/ui/components/map_settings_bottom_sheet.dart';

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

    testWidgets('MapSettingsBottomSheet renders, triggers toggle, and selects filter', (tester) async {
      bool toggledValue = false;
      MapReportFilter selectedFilter = MapReportFilter.all;

      await tester.pumpWidget(
        createLocalizedApp(
          MapSettingsBottomSheet(
            isDensityEnabled: false,
            currentFilter: MapReportFilter.all,
            onDensityToggle: (val) {
              toggledValue = val;
            },
            onFilterSelected: (filter) {
              selectedFilter = filter;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt bản đồ'), findsOneWidget);
      expect(find.text('Hiển thị mật độ phản ánh'), findsOneWidget);
      expect(find.text('Bộ lọc báo cáo'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Phản ánh của tôi'), findsOneWidget);
      expect(find.text('Đang chờ'), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.text('Đã xử lý'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(toggledValue, isTrue);

      // Tap filter chip
      await tester.tap(find.text('Đang chờ'));
      await tester.pumpAndSettle();
      expect(selectedFilter, equals(MapReportFilter.pending));
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
  });
}
