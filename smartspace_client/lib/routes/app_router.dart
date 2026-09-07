import 'package:go_router/go_router.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/auth/login/login_screen.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_email_screen.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_otp_screen.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_password_screen.dart';
import 'package:smartspace_client/ui/mobile/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_client/ui/mobile/home/home_screen.dart';
import 'package:smartspace_client/ui/mobile/map/map_screen.dart';
import 'package:smartspace_client/ui/mobile/settings/change_password_screen.dart';
import 'package:smartspace_client/ui/mobile/settings/edit_profile_screen.dart';
import 'package:smartspace_client/ui/mobile/settings/manage_devices_screen.dart';
import 'package:smartspace_client/ui/mobile/settings/settings_screen.dart';
import 'package:smartspace_client/ui/shared/splash/splash_screen.dart';
import 'package:smartspace_client/ui/mobile/auth/register/complete_profile_screen.dart';
import 'package:smartspace_client/ui/mobile/reports/create_report_screen.dart';
import 'package:smartspace_client/ui/mobile/reports/presentation/report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';

/// Re-export for convenience so existing callers of navigatorKey still compile.
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
      path: RouterPath.registerEmail,
      builder: (context, state) => const MobileRegisterEmailScreen(),
    ),
    GoRoute(
      path: RouterPath.registerOtp,
      builder: (context, state) => const MobileRegisterOtpScreen(),
    ),
    GoRoute(
      path: RouterPath.registerPassword,
      builder: (context, state) => const MobileRegisterPasswordScreen(),
    ),
    GoRoute(
      path: RouterPath.home,
      builder: (context, state) => const MobileHomeScreen(),
    ),
    GoRoute(
      path: RouterPath.completeProfile,
      builder: (context, state) => const MobileCompleteProfileScreen(),
    ),
    GoRoute(
      path: RouterPath.forgotPassword,
      builder: (context, state) => const MobileForgotPasswordScreen(),
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
      path: RouterPath.manageDevices,
      builder: (context, state) => const MobileManageDevicesScreen(),
    ),
    GoRoute(
      path: RouterPath.editProfile,
      builder: (context, state) => const MobileEditProfileScreen(),
    ),
    GoRoute(
      path: RouterPath.createReport,
      builder: (context, state) => const CreateReportScreen(),
    ),
    GoRoute(
      path: RouterPath.map,
      builder: (context, state) => const MobileMapScreen(),
    ),
    GoRoute(
      path: RouterPath.reportDetail,
      builder: (context, state) =>
          ReportDetailScreen(reportId: state.pathParameters['id']!),
    ),
  ],
);
