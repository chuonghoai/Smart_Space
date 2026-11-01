import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_admin/features/notifications/services/notification_service.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/components/sidebar.dart';

class _TestNotificationRepo implements NotificationRepo {
  const _TestNotificationRepo();

  @override
  Future<ApiResponse<NotificationCountModel>> getUnreadCount() async {
    return ApiResponse(
      success: true,
      message: 'OK',
      data: NotificationCountModel(notifNumber: 0),
    );
  }

  @override
  Future<ApiResponse<List<NotificationModel>>> getMyNotifications(
      {int page = 0, int size = 20}) async {
    return ApiResponse(success: true, message: 'OK', data: []);
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    return ApiResponse(success: true, message: 'OK');
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    return ApiResponse(success: true, message: 'OK');
  }
}

Widget _buildTestAppWithRouter(GoRouter router) {
  return ProviderScope(
    overrides: [
      notificationProvider.overrideWith(
        (ref) => NotificationNotifier(
          const NotificationService(notificationRepo: _TestNotificationRepo()),
        ),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sidebar (Mobile Drawer) Focus and Navigation Tests', () {
    testWidgets('Focuses Overview (Tổng quan) when on /home', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: RouterPath.home,
        routes: [
          GoRoute(
            path: RouterPath.home,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Home Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestAppWithRouter(router));
      await tester.pumpAndSettle();

      // Open the Drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Check that Overview is selected and others are not
      final overviewTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tổng quan'),
      );
      expect(overviewTile.selected, isTrue);

      final newsTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Quản lý tin tức'),
      );
      expect(newsTile.selected, isFalse);
    });

    testWidgets('Focuses News item when on /news, and Overview is not focused', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: RouterPath.newsManagement,
        routes: [
          GoRoute(
            path: RouterPath.home,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Home Screen'),
            ),
          ),
          GoRoute(
            path: RouterPath.newsManagement,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('News Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestAppWithRouter(router));
      await tester.pumpAndSettle();

      // Open the Drawer on /news
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // News should be selected
      final newsTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Quản lý tin tức'),
      );
      expect(newsTile.selected, isTrue);

      // Overview should NOT be selected
      final overviewTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tổng quan'),
      );
      expect(overviewTile.selected, isFalse);

      // Tapping Overview navigates back to Home
      await tester.tap(find.widgetWithText(ListTile, 'Tổng quan'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Focuses Staff Wallets item when on /admin/wallets/withdrawals (Quick Access route)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: RouterPath.adminWithdrawalRequests,
        routes: [
          GoRoute(
            path: RouterPath.home,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Home Screen'),
            ),
          ),
          GoRoute(
            path: RouterPath.adminWithdrawalRequests,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Withdrawals Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestAppWithRouter(router));
      await tester.pumpAndSettle();

      // Open the Drawer on /admin/wallets/withdrawals
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Staff Wallets should be selected
      final walletTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Quản lý ví nhân viên'),
      );
      expect(walletTile.selected, isTrue);

      // Overview should NOT be selected
      final overviewTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tổng quan'),
      );
      expect(overviewTile.selected, isFalse);

      // Tapping Overview navigates back to Home
      await tester.tap(find.widgetWithText(ListTile, 'Tổng quan'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Focuses Staff Management when on /staff-management', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: RouterPath.staffManagement,
        routes: [
          GoRoute(
            path: RouterPath.home,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Home Screen'),
            ),
          ),
          GoRoute(
            path: RouterPath.staffManagement,
            builder: (context, state) => Scaffold(
              drawer: const Sidebar(),
              body: const Text('Staff Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestAppWithRouter(router));
      await tester.pumpAndSettle();

      // Open the Drawer on /staff-management
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final staffTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Quản lý nhân viên'),
      );
      expect(staffTile.selected, isTrue);

      final overviewTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tổng quan'),
      );
      expect(overviewTile.selected, isFalse);
    });
  });
}
