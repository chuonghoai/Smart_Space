import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/auth/login/login_screen.dart';
import 'package:smartspace_staff/ui/shared/splash/splash_screen.dart';
import 'package:smartspace_staff/ui/mobile/home/home_screen.dart';
import 'package:smartspace_staff/ui/mobile/search/search_screen.dart';
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
      path: RouterPath.home,
      builder: (context, state) => const MobileHomeScreen(),
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
  ],
);
