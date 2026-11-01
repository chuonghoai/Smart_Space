import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_admin/features/map/models/report_timeframe.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/map_controls.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/map_density_legend.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/map_settings_bottom_sheet.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('MapDensityLegend renders 3 density levels and title', (tester) async {
    await tester.pumpWidget(_buildTestApp(const MapDensityLegend()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.text('Mật độ phản ánh'), findsOneWidget);
    expect(find.text('Thấp (1 - 3)'), findsOneWidget);
    expect(find.text('Trung bình (4 - 7)'), findsOneWidget);
    expect(find.text('Cao (>= 8)'), findsOneWidget);
  });

  testWidgets('MapControls renders settings, my location, and refresh buttons', (tester) async {
    bool settingsTapped = false;
    bool locationTapped = false;
    bool refreshTapped = false;

    await tester.pumpWidget(_buildTestApp(
      Stack(
        children: [
          MapControls(
            isDensityActive: true,
            onSettingsPressed: () => settingsTapped = true,
            onMyLocationPressed: () => locationTapped = true,
            onRefreshPressed: () => refreshTapped = true,
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byIcon(Icons.layers_outlined));
    expect(settingsTapped, isTrue);

    await tester.tap(find.byIcon(Icons.my_location));
    expect(locationTapped, isTrue);

    await tester.tap(find.byIcon(Icons.refresh));
    expect(refreshTapped, isTrue);
  });

  testWidgets('MapSettingsBottomSheet renders toggle, status chips, and timeframe chips', (tester) async {
    bool? densityValue;
    String? selectedStatus;
    ReportTimeframe? selectedTimeframe;

    await tester.pumpWidget(_buildTestApp(
      MapSettingsBottomSheet(
        isDensityEnabled: true,
        onDensityToggle: (val) => densityValue = val,
        currentStatus: null,
        onStatusSelected: (status) => selectedStatus = status,
        currentTimeframe: ReportTimeframe.all,
        onTimeframeSelected: (tf) => selectedTimeframe = tf,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt bản đồ'), findsOneWidget);
    expect(find.text('Mật độ phản ánh'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Toggle switch
    await tester.tap(find.byType(Switch));
    expect(densityValue, isFalse);

    // Status chips
    expect(find.text('Tất cả'), findsNWidgets(2)); // One in status, one in timeframe
    expect(find.text('Đang chờ'), findsOneWidget);

    // Tap 'Đang chờ'
    await tester.tap(find.text('Đang chờ'));
    expect(selectedStatus, 'pending');

    // Timeframe chips
    expect(find.text('1 tháng'), findsOneWidget);
    expect(find.text('3 tháng'), findsOneWidget);
    expect(find.text('6 tháng'), findsOneWidget);
    expect(find.text('9 tháng'), findsOneWidget);
    expect(find.text('12 tháng'), findsOneWidget);

    // Tap '3 tháng'
    await tester.tap(find.text('3 tháng'));
    expect(selectedTimeframe, ReportTimeframe.month3);
  });
}
