import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
      Locale('zh'),
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

    testWidgets('MapSettingsBottomSheet renders and triggers toggle', (tester) async {
      bool toggledValue = false;

      await tester.pumpWidget(
        createLocalizedApp(
          MapSettingsBottomSheet(
            isDensityEnabled: false,
            onDensityToggle: (val) {
              toggledValue = val;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt bản đồ'), findsOneWidget);
      expect(find.text('Hiển thị mật độ phản ánh'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggledValue, isTrue);
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

