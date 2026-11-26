import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/admin_accounts/application/admin_account_providers.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_list_response.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/admin_board_shared_widgets.dart';

/// Trả dữ liệu cố định, không gọi API.
class _FakeAdminAccountListNotifier extends AdminAccountListNotifier {
  @override
  Future<AdminAccountListState> build() async {
    ref.watch(adminStatusFilterProvider); // giữ hành vi rebuild khi đổi filter
    return const AdminAccountListState(
      summary: AdminAccountSummary(total: 5, active: 4, blocked: 1),
      admins: [],
      currentPage: 1,
      totalPages: 1,
      totalElements: 0,
    );
  }
}

Future<ProviderContainer> _pumpBadges(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminAccountListProvider.overrideWith(_FakeAdminAccountListNotifier.new),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const Scaffold(body: AdminSummaryBadges()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(AdminSummaryBadges)));
}

void main() {
  // Test Case ID: SMP-092
  // Description: Kiểm tra AdminSummaryBadges hiển thị đủ 3 badge Tổng, Hoạt động, Đã khoá kèm đúng số liệu.
  testWidgets('Hiển thị đủ 3 badge kèm số liệu', (tester) async {
    await _pumpBadges(tester);

    expect(find.text('Tổng'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Đã khoá'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  // Test Case ID: SMP-093
  // Description: Kiểm tra bấm badge cập nhật adminStatusFilterProvider và bấm lại badge đang chọn sẽ bỏ lọc về all.
  testWidgets('Bấm badge → lọc; bấm lại badge đang chọn → bỏ lọc', (tester) async {
    final container = await _pumpBadges(tester);
    expect(container.read(adminStatusFilterProvider), 'all');

    await tester.tap(find.text('Đã khoá'));
    await tester.pumpAndSettle();
    expect(container.read(adminStatusFilterProvider), 'blocked');

    await tester.tap(find.text('Đã khoá'));
    await tester.pumpAndSettle();
    expect(container.read(adminStatusFilterProvider), 'all');

    await tester.tap(find.text('Hoạt động'));
    await tester.pumpAndSettle();
    expect(container.read(adminStatusFilterProvider), 'active');

    await tester.tap(find.text('Tổng'));
    await tester.pumpAndSettle();
    expect(container.read(adminStatusFilterProvider), 'all');
  });

  // Test Case ID: SMP-094
  // Description: Kiểm tra AdminSummaryBadges render bình thường ở Dark Mode mà không phát sinh exception.
  testWidgets('Render được ở Dark mode', (tester) async {
    await _pumpBadges(tester, theme: AppTheme.darkTheme);

    expect(find.text('Đã khoá'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
