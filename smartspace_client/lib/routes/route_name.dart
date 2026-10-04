import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class AppRouteInfo {
  final String path;
  final String nameKey;
  final IconData icon;
  final bool isHiddenInSearch;
  final int priority;

  const AppRouteInfo({
    required this.path,
    required this.nameKey,
    required this.icon,
    this.isHiddenInSearch = false,
    this.priority = 99,
  });

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (nameKey) {
      case 'routeHome':
        return l10n.routeHome;
      case 'routeSettings':
        return l10n.routeSettings;
      case 'routeMap':
        return l10n.routeMap;
      case 'routeCreateReport':
        return l10n.routeCreateReport;
      case 'routeMyReports':
        return l10n.routeMyReports;
      case 'routeCommunityFeed':
        return l10n.routeCommunityFeed;
      case 'routeEditProfile':
        return l10n.routeEditProfile;
      case 'routeChangePassword':
        return l10n.routeChangePassword;
      case 'routeManageDevices':
        return l10n.routeManageDevices;
      case 'routeNotifications':
        return l10n.routeNotifications;
      default:
        return nameKey;
    }
  }
}

class RouteName {
  static const splash = AppRouteInfo(
    path: '/splash',
    nameKey: 'routeSplash',
    icon: Icons.water_drop,
    isHiddenInSearch: true,
  );
  static const login = AppRouteInfo(
    path: '/login',
    nameKey: 'routeLogin',
    icon: Icons.login,
    isHiddenInSearch: true,
  );
  static const registerEmail = AppRouteInfo(
    path: '/register-email',
    nameKey: 'routeRegister',
    icon: Icons.app_registration,
    isHiddenInSearch: true,
  );
  static const registerOtp = AppRouteInfo(
    path: '/register-otp',
    nameKey: 'routeRegister',
    icon: Icons.password,
    isHiddenInSearch: true,
  );
  static const registerPassword = AppRouteInfo(
    path: '/register-password',
    nameKey: 'routeRegister',
    icon: Icons.password,
    isHiddenInSearch: true,
  );
  static const home = AppRouteInfo(
    path: '/home',
    nameKey: 'routeHome',
    icon: Icons.home,
    priority: 1,
  );
  static const completeProfile = AppRouteInfo(
    path: '/complete-profile',
    nameKey: 'routeCompleteProfile',
    icon: Icons.person,
    isHiddenInSearch: true,
  );
  static const forgotPassword = AppRouteInfo(
    path: '/forgot-password',
    nameKey: 'routeForgotPassword',
    icon: Icons.lock_reset,
    isHiddenInSearch: true,
  );
  static const settings = AppRouteInfo(
    path: '/settings',
    nameKey: 'routeSettings',
    icon: Icons.settings,
    priority: 5,
  );
  static const changePassword = AppRouteInfo(
    path: '/change-password',
    nameKey: 'routeChangePassword',
    icon: Icons.password,
    priority: 6,
  );
  static const manageDevices = AppRouteInfo(
    path: '/manage-devices',
    nameKey: 'routeManageDevices',
    icon: Icons.devices,
    priority: 7,
  );
  static const editProfile = AppRouteInfo(
    path: '/edit-profile',
    nameKey: 'routeEditProfile',
    icon: Icons.edit,
    priority: 8,
  );
  static const createReport = AppRouteInfo(
    path: '/create-report',
    nameKey: 'routeCreateReport',
    icon: Icons.add_circle,
    priority: 2,
  );
  static const map = AppRouteInfo(
    path: '/map',
    nameKey: 'routeMap',
    icon: Icons.map,
    priority: 3,
  );
  static const reportDetail = AppRouteInfo(
    path: '/reports/:id',
    nameKey: 'routeReportDetail',
    icon: Icons.description,
    isHiddenInSearch: true,
  );
  static const myReports = AppRouteInfo(
    path: '/my-reports',
    nameKey: 'routeMyReports',
    icon: Icons.receipt_long,
    priority: 4,
  );
  static const search = AppRouteInfo(
    path: '/search',
    nameKey: 'search',
    icon: Icons.search,
    isHiddenInSearch: true,
  );
  static const notifications = AppRouteInfo(
    path: '/notifications',
    nameKey: 'routeNotifications',
    icon: Icons.notifications,
    priority: 9,
  );
  static const communityFeed = AppRouteInfo(
    path: '/community-feed',
    nameKey: 'routeCommunityFeed',
    icon: Icons.dynamic_feed,
    priority: 3,
  );

  static const List<AppRouteInfo> allRoutes = [
    splash,
    login,
    registerEmail,
    registerOtp,
    registerPassword,
    home,
    completeProfile,
    forgotPassword,
    settings,
    changePassword,
    manageDevices,
    editProfile,
    createReport,
    map,
    reportDetail,
    myReports,
    search,
    notifications,
    communityFeed,
  ];

  static List<AppRouteInfo> get searchableRoutes {
    final list = allRoutes.where((r) => !r.isHiddenInSearch).toList();
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }
}
