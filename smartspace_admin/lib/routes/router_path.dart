import 'package:smartspace_admin/routes/route_name.dart';

class RouterPath {
  static String get splash => RouteName.splash.path;
  static String get login => RouteName.login.path;
  static String get home => RouteName.home.path;
  static String get reportDetail => RouteName.reportDetail.path;
  static String reportDetailWithId(String id) =>
      RouteName.reportDetail.path.replaceAll(':id', id);
  static String get completeProfile => RouteName.completeProfile.path;
  static String get forgotPassword => RouteName.forgotPassword.path;
  static String get settings => RouteName.settings.path;
  static String get editProfile => RouteName.editProfile.path;
  static String get changePassword => RouteName.changePassword.path;
  static String get staffManagement => RouteName.staffManagement.path;
  static String get userManagement => RouteName.userManagement.path;
  static String get positionManagement => RouteName.positionManagement.path;
  static String get reportDashboard => RouteName.reportDashboard.path;
  static String get reportList => RouteName.reportList.path;
  static String get spaceMap => RouteName.spaceMap.path;
  static String get search => RouteName.search.path;
  static String get notifications => RouteName.notifications.path;
  static String get manageDevices => RouteName.manageDevices.path;
  static String get unsatisfactoryReports => RouteName.unsatisfactoryReports.path;
  static String get newsManagement => RouteName.newsManagement.path;
  static String get createNews => RouteName.createNews.path;
  static String newsDetailWithId(String id) =>
      RouteName.newsDetail.path.replaceAll(':id', id);
  static String editNewsWithId(String id) =>
      RouteName.editNews.path.replaceAll(':id', id);
}
