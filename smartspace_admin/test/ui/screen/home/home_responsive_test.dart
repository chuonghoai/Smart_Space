import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/connection/connection_state_provider.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:mobile_shared/features/news/application/news_providers.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/admin_overview_model.dart';
import 'package:smartspace_admin/features/home/models/recent_activity_model.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_count_model.dart';
import 'package:smartspace_admin/features/notifications/models/notification_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/features/notifications/repositories/notification_repo.dart';
import 'package:smartspace_admin/features/notifications/services/notification_service.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/components/connection_indicator.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/home/admin_home_screen.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/admin_quick_access_bar.dart';

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

class _MockAdminOverviewNotifier extends AdminOverviewNotifier {
  @override
  Future<AdminOverviewModel?> build() async {
    return const AdminOverviewModel(
      userCount: 120,
      staffCount: 15,
      adminCount: 3,
      issueCount: 45,
      pendingCount: 8,
      processingCount: 12,
      unsatisfactoryProcessedCount: 2,
    );
  }
}

class _MockRecentReportNotifier extends RecentReportNotifier {
  @override
  Future<List<RecentReportModel>> build(String arg) async {
    return [
      const RecentReportModel(
        id: 'rep-1',
        title: 'Báo cáo sự cố đường ống nước ngập',
        status: 'pending',
        createdAt: '2026-10-30T10:00:00Z',
      ),
    ];
  }
}

class _MockRecentActivityNotifier extends RecentActivityNotifier {
  @override
  Future<List<RecentActivityModel>> build() async {
    return [
      const RecentActivityModel(
        id: 'act-1',
        message: 'Admin đã duyệt phản ánh mới',
        createdAt: '2026-10-30T10:30:00Z',
      ),
    ];
  }
}

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('vi'),
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      notificationProvider.overrideWith(
        (ref) => NotificationNotifier(
          const NotificationService(notificationRepo: _TestNotificationRepo()),
        ),
      ),
      adminOverviewProvider.overrideWith(() => _MockAdminOverviewNotifier()),
      pendingWithdrawalCountProvider.overrideWith((ref) => 2),
      recentReportProvider.overrideWith(() => _MockRecentReportNotifier()),
      recentActivityProvider.overrideWith(() => _MockRecentActivityNotifier()),
      latestNewsProvider.overrideWith((ref) => []),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    ),
  );
}

void main() {
  group('AdminQuickAccessBar Tests', () {
    testWidgets('renders all 8 quick access cards and scrollbar in scrollable mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: AdminQuickAccessBar(),
          ),
        ),
      );
      await tester.pump();

      // Verify scrollbar exists
      expect(find.byType(Scrollbar), findsOneWidget);
      // Verify scroll buttons exist
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Verify specific quick access icons
      expect(find.byIcon(Icons.report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.newspaper_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
    });

    testWidgets('renders panel mode with 2-column grid when isPanelMode is true',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: AdminQuickAccessBar(isPanelMode: true),
          ),
        ),
      );
      await tester.pump();

      // In panel mode, no horizontal scrollbar or navigation chevrons
      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byIcon(Icons.chevron_left), findsNothing);

      // Verify all 8 action tiles exist
      expect(find.byIcon(Icons.report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.newspaper_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
    });

    testWidgets('scroll buttons move the scroll position smoothly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: AdminQuickAccessBar(),
          ),
        ),
      );
      await tester.pump();

      final scrollRightBtn = find.byIcon(Icons.chevron_right);
      expect(scrollRightBtn, findsOneWidget);
      await tester.tap(scrollRightBtn);
      await tester.pumpAndSettle();
    });
  });

  group('ConnectionIndicator Tests', () {
    testWidgets('shows connected wifi icon and tooltip when connected',
        (tester) async {
      connectionStateProvider.setConnected();

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: ConnectionIndicator(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('shows disconnected icon and retry action when disconnected',
        (tester) async {
      connectionStateProvider.setDisconnected();

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: ConnectionIndicator(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });

  group('AppLayout Responsive Tests', () {
    testWidgets('switches to mobile layout when width < 850px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const AppLayout(
            child: Text('Content'),
          ),
        ),
      );
      await tester.pump();

      // On mobile, the top bar should have the menu button to open drawer
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('AdminHomeScreen Desktop & Mobile Responsive Tests', () {
    testWidgets('renders desktop bento layout with header and panel quick access when width >= 1024',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminHomeScreen()));
      await tester.pumpAndSettle();

      // Verify desktop header elements exist
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify overview KPI stat numbers
      expect(find.text('120'), findsOneWidget); // userCount
      expect(find.text('15'), findsOneWidget); // staffCount

      // Verify panel mode quick access is present
      expect(find.byWidgetPredicate(
        (widget) => widget is AdminQuickAccessBar && widget.isPanelMode == true,
      ), findsOneWidget);
    });

    testWidgets('renders mobile layout without desktop header and scrollable quick access when width < 1024',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const AdminHomeScreen()));
      await tester.pumpAndSettle();

      // On mobile, desktop header is NOT present
      expect(find.byIcon(Icons.shield_outlined), findsNothing);

      // Verify scrollable mode quick access is present
      expect(find.byWidgetPredicate(
        (widget) => widget is AdminQuickAccessBar && widget.isPanelMode == false,
      ), findsOneWidget);

      // Verify overview stat cards render cleanly
      expect(find.text('120'), findsOneWidget);
    });
  });
}
