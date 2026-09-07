import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/register/register_email_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/register/register_otp_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/register/register_password_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_admin/ui/screen/home/home_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/change_password_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/settings_screen.dart';
import 'package:smartspace_admin/ui/shared/splash/splash_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/register/complete_profile_screen.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
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
  ],
);
