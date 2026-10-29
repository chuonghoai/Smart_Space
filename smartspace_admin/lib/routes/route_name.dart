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
      case 'routeUserManagement':
        return l10n.routeUserManagement;
      case 'routeReportDashboard':
        return l10n.routeReportDashboard;
      case 'routeReportList':
        return l10n.routeReportList;
      case 'routeSpaceMap':
        return l10n.routeSpaceMap;
      case 'routeNotifications':
        return l10n.routeNotifications;
      case 'routePositionManagement':
        return l10n.routePositionManagement;
      case 'routeManageDevices':
        return l10n.routeManageDevices;
      case 'routeUnsatisfactoryReports':
        return l10n.routeUnsatisfactoryReports;
      case 'routeNewsManagement':
        return l10n.routeNewsManagement;
      case 'routeCreateNews':
        return l10n.routeCreateNews;
      case 'routeNewsDetail':
        return l10n.routeNewsDetail;
      case 'routeEditNews':
        return l10n.routeEditNews;
      case 'routeAllActivities':
        return l10n.routeAllActivities;
      case 'routeWalletConfig':
        return l10n.routeWalletConfig;
      case 'routeManageStaffWallets':
        return l10n.routeManageStaffWallets;
      case 'routeWithdrawalRequests':
        return l10n.routeWithdrawalRequests;
      case 'routeStaffWalletDetail':
        return l10n.routeStaffWalletDetail;
      case 'routeSystemConfig':
        return l10n.routeSystemConfig;
      case 'routeCommissionConfig':
        return l10n.routeCommissionConfig;
      case 'routePenaltyRateConfig':
        return l10n.routePenaltyRateConfig;
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
  static const userManagement = AppRouteInfo(
    path: '/user-management',
    nameKey: 'routeUserManagement',
    icon: Icons.people_outline,
    priority: 2,
  );
  static const positionManagement = AppRouteInfo(
    path: '/position-management',
    nameKey: 'routePositionManagement',
    icon: Icons.workspace_premium,
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
  static const manageDevices = AppRouteInfo(
    path: '/manage-devices',
    nameKey: 'routeManageDevices',
    icon: Icons.phone_android,
    isHiddenInSearch: true,
  );
  static const unsatisfactoryReports = AppRouteInfo(
    path: '/reports/unsatisfactory',
    nameKey: 'routeUnsatisfactoryReports',
    icon: Icons.report_problem_outlined,
    priority: 4,
  );
  static const newsManagement = AppRouteInfo(
    path: '/news',
    nameKey: 'routeNewsManagement',
    icon: Icons.newspaper_outlined,
    priority: 5,
  );
  static const createNews = AppRouteInfo(
    path: '/news/create',
    nameKey: 'routeCreateNews',
    icon: Icons.post_add,
    isHiddenInSearch: true,
  );
  static const newsDetail = AppRouteInfo(
    path: '/news/:id',
    nameKey: 'routeNewsDetail',
    icon: Icons.article_outlined,
    isHiddenInSearch: true,
  );
  static const editNews = AppRouteInfo(
    path: '/news/edit/:id',
    nameKey: 'routeEditNews',
    icon: Icons.edit_note,
    isHiddenInSearch: true,
  );
  static const allActivities = AppRouteInfo(
    path: '/activities',
    nameKey: 'routeAllActivities',
    icon: Icons.history,
    priority: 8,
  );
  static const walletConfig = AppRouteInfo(
    path: '/wallet-config',
    nameKey: 'routeWalletConfig',
    icon: Icons.account_balance_wallet_outlined,
    priority: 6,
  );
  static const adminStaffWallets = AppRouteInfo(
    path: '/admin/wallets',
    nameKey: 'routeManageStaffWallets',
    icon: Icons.account_balance_wallet_outlined,
    priority: 5,
  );
  static const adminWithdrawalRequests = AppRouteInfo(
    path: '/admin/wallets/withdrawals',
    nameKey: 'routeWithdrawalRequests',
    icon: Icons.pending_actions_outlined,
    isHiddenInSearch: true,
  );
  static const adminStaffWalletDetail = AppRouteInfo(
    path: '/admin/wallets/staff/:id',
    nameKey: 'routeStaffWalletDetail',
    icon: Icons.wallet_outlined,
    isHiddenInSearch: true,
  );
  static const systemConfig = AppRouteInfo(
    path: '/system-config',
    nameKey: 'routeSystemConfig',
    icon: Icons.tune_outlined,
    priority: 6,
  );
  static const commissionConfig = AppRouteInfo(
    path: '/system-config/commission',
    nameKey: 'routeCommissionConfig',
    icon: Icons.monetization_on_outlined,
    isHiddenInSearch: true,
  );
  static const penaltyRateConfig = AppRouteInfo(
    path: '/system-config/penalty-rate',
    nameKey: 'routePenaltyRateConfig',
    icon: Icons.percent_outlined,
    isHiddenInSearch: true,
  );

  static const List<AppRouteInfo> allRoutes = [
    splash,
    login,
    home,
    reportDetail,
    completeProfile,
    forgotPassword,
    settings,
    walletConfig,
    adminStaffWallets,
    adminWithdrawalRequests,
    adminStaffWalletDetail,
    systemConfig,
    commissionConfig,
    penaltyRateConfig,
    editProfile,
    changePassword,
    staffManagement,
    userManagement,
    positionManagement,
    reportDashboard,
    reportList,
    unsatisfactoryReports,
    spaceMap,
    search,
    notifications,
    manageDevices,
    newsManagement,
    createNews,
    newsDetail,
    editNews,
    allActivities,
  ];

  static List<AppRouteInfo> get searchableRoutes {
    final list = allRoutes.where((r) => !r.isHiddenInSearch).toList();
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }
}
