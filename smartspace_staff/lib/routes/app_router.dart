import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/auth/login/login_screen.dart';
import 'package:smartspace_staff/ui/shared/splash/splash_screen.dart';
import 'package:smartspace_staff/ui/mobile/home/home_screen.dart';
import 'package:smartspace_staff/ui/mobile/notifications/staff_notification_screen.dart';
import 'package:smartspace_staff/ui/mobile/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_staff/ui/mobile/reports/presentation/report_detail_screen.dart';
import 'package:smartspace_staff/ui/mobile/reports/presentation/handle_report_screen.dart';
import 'package:smartspace_staff/ui/mobile/reports/all_reports_screen.dart';
import 'package:smartspace_staff/ui/mobile/map/map_screen.dart';
import 'package:smartspace_staff/ui/mobile/settings/change_password_screen.dart';
import 'package:smartspace_staff/ui/mobile/settings/edit_profile_screen.dart';
import 'package:smartspace_staff/ui/mobile/settings/manage_devices_screen.dart';
import 'package:smartspace_staff/ui/mobile/settings/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = sharedNavigatorKey;

final appRouter = GoRouter(
  navigatorKey: sharedNavigatorKey,
  initialLocation: RouterPath.splash,
  routes: [
    GoRoute(
      path: RouterPath.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouterPath.login,
      builder: (context, state) => const MobileLoginScreen(),
    ),
    GoRoute(
      path: RouterPath.home,
      builder: (context, state) => const MobileHomeScreen(),
    ),
    GoRoute(
      path: RouterPath.notifications,
      builder: (context, state) => const StaffNotificationScreen(),
    ),
    GoRoute(
      path: RouterPath.allReports,
      builder: (context, state) {
        final initialFilter = state.uri.queryParameters['filter'] ?? 'all';
        return AllReportsScreen(initialFilter: initialFilter);
      },
    ),
    GoRoute(
      path: RouterPath.reportDetail,
      builder: (context, state) =>
          ReportDetailScreen(reportId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: RouterPath.handleReport,
      builder: (context, state) =>
          HandleReportScreen(reportId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: RouterPath.search,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MobileSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: RouterPath.map,
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: RouterPath.settings,
      builder: (context, state) => const MobileSettingsScreen(),
    ),
    GoRoute(
      path: RouterPath.changePassword,
      builder: (context, state) => const MobileChangePasswordScreen(),
    ),
    GoRoute(
      path: RouterPath.editProfile,
      builder: (context, state) => const MobileEditProfileScreen(),
    ),
    GoRoute(
      path: RouterPath.manageDevices,
      builder: (context, state) => const MobileManageDevicesScreen(),
    ),
  ],
);
