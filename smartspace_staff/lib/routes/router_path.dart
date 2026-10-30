import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:smartspace_staff/routes/route_name.dart';

class RouterPath {
  static String get splash => RouteName.splash.path;
  static String get login => RouteName.login.path;
  static String get home => RouteName.home.path;
  static String get notifications => RouteName.notifications.path;
  static String get settings => RouteName.settings.path;
  static String get changePassword => RouteName.changePassword.path;
  static String get editProfile => RouteName.editProfile.path;
  static String get manageDevices => RouteName.manageDevices.path;
  static String get reportDetail => RouteName.reportDetail.path;
  static String get search => RouteName.search.path;
  static String get allReports => RouteName.allReports.path;
  static String get map => RouteName.map.path;
  static String mapWithFocus(MapFocusTarget focus) => focus.toLocation(map);
  static String get handleReport => RouteName.handleReport.path;
  static String get news => RouteName.news.path;
  static String get staffWallet => RouteName.staffWallet.path;
  static String get staffWalletTransactions =>
      RouteName.staffWalletTransactions.path;
    static String get staffWithdrawal => RouteName.staffWithdrawal.path;
  static String get staffWithdrawalHistory =>
      RouteName.staffWithdrawalHistory.path;
  static String staffWithdrawalDetailWithId(String id) =>
      RouteName.staffWithdrawalDetail.path.replaceAll(':id', id);
  static String get staffBankAccounts => RouteName.staffBankAccounts.path;
  static String newsDetailWithId(String id) =>
      RouteName.newsDetail.path.replaceAll(':id', id);
}
