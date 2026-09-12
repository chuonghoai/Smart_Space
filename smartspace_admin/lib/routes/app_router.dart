import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_admin/ui/screen/home/admin_home_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/change_password_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/settings_screen.dart';
import 'package:smartspace_admin/ui/shared/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_shared/mobile_shared.dart';

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
      path: RouterPath.home,
      builder: (context, state) => const AdminHomeScreen(),
    ),
    GoRoute(
      path: RouterPath.login,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: RouterPath.forgotPassword,
      builder: (context, state) => const AdminForgotPasswordScreen(),
    ),
    GoRoute(
      path: RouterPath.settings,
      builder: (context, state) => const MobileSettingsScreen(),
    ),
    GoRoute(
      path: RouterPath.changePassword,
      builder: (context, state) => const MobileChangePasswordScreen(),
    ),
  ],
);
