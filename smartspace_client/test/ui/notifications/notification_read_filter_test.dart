import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/notifications/widgets/notification_read_filter.dart';

Widget _host({required ThemeData theme, required bool unreadOnly, required int count, ValueChanged<bool>? onChanged}) =>
    MaterialApp(
      theme: theme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NotificationReadFilter(unreadOnly: unreadOnly, unreadCount: count, onChanged: onChanged ?? (_) {}),
        ),
      ),
    );

void main() {
  for (final (name, theme) in [('light', AppTheme.lightTheme), ('dark', AppTheme.darkTheme)]) {
    testWidgets('[$name] hiện 2 nửa, badge số chưa đọc, chạm "Chưa đọc" gọi onChanged(true)', (tester) async {
      bool? changedTo;
      await tester.pumpWidget(_host(theme: theme, unreadOnly: false, count: 5, onChanged: (v) => changedTo = v));

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('Chưa đọc'));
      expect(changedTo, isTrue);
    });
  }

  testWidgets('chạm lại nửa đang chọn không gọi onChanged; quá 99 hiện 99+', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(theme: AppTheme.lightTheme, unreadOnly: true, count: 120, onChanged: (_) => calls++));

    expect(find.text('99+'), findsOneWidget);
    await tester.tap(find.text('Chưa đọc'));
    expect(calls, 0);
  });

  testWidgets('không có chưa đọc thì không hiện badge; semantics báo nửa đang chọn', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(theme: AppTheme.lightTheme, unreadOnly: false, count: 0));

    expect(find.text('0'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tất cả')),
      matchesSemantics(isButton: true, isSelected: true, isInMutuallyExclusiveGroup: true, hasSelectedState: true),
    );
    handle.dispose();
  });
}
