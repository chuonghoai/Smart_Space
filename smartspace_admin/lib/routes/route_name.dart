import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

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
      case 'routeEditProfile':
        return l10n.routeEditProfile;
      case 'routeChangePassword':
        return l10n.routeChangePassword;
      case 'routeStaffManagement':
        return l10n.routeStaffManagement;
      case 'routeReportDashboard':
        return l10n.routeReportDashboard;
      case 'routeReportList':
        return l10n.routeReportList;
      case 'routeSpaceMap':
        return l10n.routeSpaceMap;
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
  static const home = AppRouteInfo(
    path: '/home',
    nameKey: 'routeHome',
    icon: Icons.home,
    priority: 1,
  );
  static const reportDetail = AppRouteInfo(
    path: '/reports/:id',
    nameKey: 'routeReportDetail',
    icon: Icons.description,
    isHiddenInSearch: true,
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
  static const editProfile = AppRouteInfo(
    path: '/settings/edit-profile',
    nameKey: 'routeEditProfile',
    icon: Icons.edit,
    priority: 6,
  );
  static const changePassword = AppRouteInfo(
    path: '/change-password',
    nameKey: 'routeChangePassword',
    icon: Icons.password,
    priority: 7,
  );
  static const staffManagement = AppRouteInfo(
    path: '/staff-management',
    nameKey: 'routeStaffManagement',
    icon: Icons.people,
    priority: 2,
  );
  static const reportDashboard = AppRouteInfo(
    path: '/report-dashboard',
    nameKey: 'routeReportDashboard',
    icon: Icons.dashboard,
    priority: 3,
  );
  static const reportList = AppRouteInfo(
    path: '/report-list',
    nameKey: 'routeReportList',
    icon: Icons.list_alt,
    priority: 4,
  );
  static const spaceMap = AppRouteInfo(
    path: '/space-map',
    nameKey: 'routeSpaceMap',
    icon: Icons.map,
    priority: 8,
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

  static const List<AppRouteInfo> allRoutes = [
    splash,
    login,
    home,
    reportDetail,
    completeProfile,
    forgotPassword,
    settings,
    editProfile,
    changePassword,
    staffManagement,
    reportDashboard,
    reportList,
    spaceMap,
    search,
    notifications,
  ];

  static List<AppRouteInfo> get searchableRoutes {
    final list = allRoutes.where((r) => !r.isHiddenInSearch).toList();
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }
}
