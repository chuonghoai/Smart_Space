import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

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
      case 'routeChangePassword':
        return l10n.routeChangePassword;
      case 'routeEditProfile':
        return l10n.routeEditProfile;
      case 'routeManageDevices':
        return l10n.routeManageDevices;
      case 'routeStaffWallet':
        return l10n.routeStaffWallet;
      case 'routeStaffWalletTransactions':
        return l10n.routeStaffWalletTransactions;
      case 'routeStaffWithdrawal':
        return l10n.routeStaffWithdrawal;
      case 'routeStaffWithdrawalHistory':
        return l10n.routeStaffWithdrawalHistory;
      case 'routeStaffWithdrawalDetail':
        return l10n.routeStaffWithdrawalDetail;
      case 'routeStaffBankAccounts':
        return l10n.routeStaffBankAccounts;
      // Add more routes here as needed
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
    isHiddenInSearch: false,
    priority: 1,
  );
  static const settings = AppRouteInfo(
    path: '/setting',
    nameKey: 'routeSettings',
    icon: Icons.settings,
    isHiddenInSearch: false,
    priority: 2,
  );
  static const changePassword = AppRouteInfo(
    path: '/change-password',
    nameKey: 'routeChangePassword',
    icon: Icons.password,
    priority: 6,
  );
  static const editProfile = AppRouteInfo(
    path: '/edit-profile',
    nameKey: 'routeEditProfile',
    icon: Icons.edit,
    isHiddenInSearch: true,
  );
  static const manageDevices = AppRouteInfo(
    path: '/manage-devices',
    nameKey: 'routeManageDevices',
    icon: Icons.phone_android,
    isHiddenInSearch: true,
  );
  static const reportDetail = AppRouteInfo(
    path: '/reports/:id',
    nameKey: 'routeReportDetail',
    icon: Icons.description,
    isHiddenInSearch: true,
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
    isHiddenInSearch: false,
    priority: 5,
  );

  static const allReports = AppRouteInfo(
    path: '/reports/all',
    nameKey: 'myWorkDashboard',
    icon: Icons.work,
    isHiddenInSearch: false,
    priority: 3,
  );

  static const map = AppRouteInfo(
    path: '/map',
    nameKey: 'routeMap',
    icon: Icons.map_outlined,
    isHiddenInSearch: false,
    priority: 4,
  );

  static const handleReport = AppRouteInfo(
    path: '/reports/:id/handle',
    nameKey: 'routeHandleReport',
    icon: Icons.assignment_turned_in_outlined,
    isHiddenInSearch: true,
  );

  static const news = AppRouteInfo(
    path: '/news',
    nameKey: 'routeNewsList',
    icon: Icons.newspaper,
    priority: 5,
  );

  static const newsDetail = AppRouteInfo(
    path: '/news/:id',
    nameKey: 'newsDetail',
    icon: Icons.newspaper,
    isHiddenInSearch: true,
  );

  static const staffWallet = AppRouteInfo(
    path: '/wallet',
    nameKey: 'routeStaffWallet',
    icon: Icons.account_balance_wallet_outlined,
    isHiddenInSearch: false,
    priority: 4,
  );

  static const staffWalletTransactions = AppRouteInfo(
    path: '/wallet/transactions',
    nameKey: 'routeStaffWalletTransactions',
    icon: Icons.history,
    isHiddenInSearch: true,
  );

  
  static const staffWithdrawal = AppRouteInfo(
    path: '/wallet/withdraw',
    nameKey: 'routeStaffWithdrawal',
    icon: Icons.arrow_upward_rounded,
    isHiddenInSearch: true,
  );

  static const staffWithdrawalHistory = AppRouteInfo(
    path: '/wallet/withdrawals',
    nameKey: 'routeStaffWithdrawalHistory',
    icon: Icons.history_rounded,
    isHiddenInSearch: true,
  );

  static const staffWithdrawalDetail = AppRouteInfo(
    path: '/wallet/withdrawals/:id',
    nameKey: 'routeStaffWithdrawalDetail',
    icon: Icons.receipt_long_rounded,
    isHiddenInSearch: true,
  );

  static const staffBankAccounts = AppRouteInfo(
    path: '/settings/bank-accounts',
    nameKey: 'routeStaffBankAccounts',
    icon: Icons.account_balance_outlined,
    isHiddenInSearch: true,
  );

  static const List<AppRouteInfo> allRoutes = [
    splash,
    login,
    home,
    notifications,
    settings,
    changePassword,
    editProfile,
    manageDevices,
    reportDetail,
    handleReport,
    search,
    allReports,
    map,
    news,
    newsDetail,
    staffWallet,
    staffWalletTransactions,
    staffWithdrawal,
    staffWithdrawalHistory,
    staffWithdrawalDetail,
    staffBankAccounts,
  ];

  static List<AppRouteInfo> get searchableRoutes {
    final list = allRoutes.where((r) => !r.isHiddenInSearch).toList();
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }
}
