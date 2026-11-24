import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/notifications/admin_notification_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/login/login_screen.dart';
import 'package:smartspace_admin/ui/screen/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_admin/ui/screen/home/admin_home_screen.dart';
import 'package:smartspace_admin/ui/screen/reports/admin_report_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/reports/report_dashboard_screen.dart';
import 'package:smartspace_admin/ui/screen/reports/report_list_screen.dart';
import 'package:smartspace_admin/ui/screen/reports/unsatisfactory_reports_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/change_password_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/edit_profile_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/settings_screen.dart';
import 'package:smartspace_admin/ui/screen/settings/manage_devices_screen.dart';
import 'package:smartspace_admin/ui/screen/map/admin_map_screen.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_management_screen.dart';
import 'package:smartspace_admin/ui/screen/users/user_management_screen.dart';
import 'package:smartspace_admin/ui/screen/position/position_management_screen.dart';
import 'package:smartspace_admin/ui/screen/category/category_management_screen.dart';
import 'package:smartspace_admin/ui/screen/auto_assign/auto_assign_center_screen.dart';
import 'package:smartspace_admin/ui/screen/admin_board/admin_board_screen.dart';
import 'package:smartspace_admin/ui/shared/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_shared/mobile_shared.dart';

import 'package:smartspace_admin/ui/screen/search/search_screen.dart';
import 'package:smartspace_admin/ui/screen/news/admin_news_list_screen.dart';
import 'package:smartspace_admin/ui/screen/news/admin_create_edit_news_screen.dart';
import 'package:smartspace_admin/ui/screen/news/admin_news_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/home/admin_all_activities_screen.dart';
import 'package:smartspace_admin/ui/screen/chat/admin_conversations_screen.dart';
import 'package:smartspace_admin/ui/screen/chat/admin_chat_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/chat/admin_conversation_info_screen.dart';

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
      path: RouterPath.conversations,
      builder: (context, state) => const AdminConversationsScreen(),
    ),
    GoRoute(
      path: RouterPath.chatDetail,
      builder: (context, state) {
        final conversationId = state.pathParameters['id'] ?? '';
        final partner = state.extra as ParticipantModel?;
        return AdminChatDetailScreen(
          conversationId: conversationId,
          partner: partner,
        );
      },
    ),
    GoRoute(
      path: RouterPath.conversationInfo,
      builder: (context, state) {
        final conversationId = state.pathParameters['id'] ?? '';
        return AdminConversationInfoScreen(
          conversationId: conversationId,
        );
      },
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
      path: RouterPath.unsatisfactoryReports,
      builder: (context, state) => const UnsatisfactoryReportsScreen(),
    ),
    GoRoute(
      path: RouterPath.reportDetail,
      builder: (context, state) {
        final reportId = state.pathParameters['id'] ?? '';
        return AdminReportDetailScreen(reportId: reportId);
      },
    ),
    GoRoute(
      path: RouterPath.settings,
      builder: (context, state) => const MobileSettingsScreen(),
    ),
    GoRoute(
      path: RouterPath.editProfile,
      builder: (context, state) => const AdminEditProfileScreen(),
    ),
    GoRoute(
      path: RouterPath.changePassword,
      builder: (context, state) => const MobileChangePasswordScreen(),
    ),
    GoRoute(
      path: RouterPath.staffManagement,
      builder: (context, state) => StaffManagementScreen(
        initialStaffId: state.uri.queryParameters['staffId'],
        initialStaff:
            state.extra is StaffModel ? state.extra as StaffModel : null,
      ),
    ),
    GoRoute(
      path: RouterPath.userManagement,
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: RouterPath.positionManagement,
      builder: (context, state) => const PositionManagementScreen(),
    ),
    GoRoute(
      path: RouterPath.categoryManagement,
      builder: (context, state) => const CategoryManagementScreen(),
    ),
    GoRoute(
      path: RouterPath.autoAssignCenter,
      builder: (context, state) => const AutoAssignCenterScreen(),
    ),
    GoRoute(
      path: RouterPath.adminBoard,
      builder: (context, state) => AdminBoardScreen(
        // key theo query để mở lại đúng tab / đề xuất khi điều hướng từ thông báo
        key: ValueKey(state.uri.query),
        initialTab: state.uri.queryParameters['tab'],
        initialRequestId: state.uri.queryParameters['requestId'],
      ),
    ),
    GoRoute(
      path: RouterPath.reportDashboard,
      builder: (context, state) => const ReportDashboardScreen(),
    ),
    GoRoute(
      path: RouterPath.reportList,
      builder: (context, state) => const ReportListScreen(),
    ),
    GoRoute(
      path: RouterPath.spaceMap,
      builder: (context, state) => AdminMapScreen(
        focus: MapFocusTarget.fromQueryParameters(state.uri.queryParameters),
      ),
    ),
    GoRoute(
      path: RouterPath.search,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: RouterPath.notifications,
      builder: (context, state) => const AdminNotificationScreen(),
    ),
    GoRoute(
      path: RouterPath.manageDevices,
      builder: (context, state) => const MobileManageDevicesScreen(),
    ),
    GoRoute(
      path: RouterPath.newsManagement,
      builder: (context, state) => const AdminNewsListScreen(),
    ),
    GoRoute(
      path: RouterPath.createNews,
      builder: (context, state) => const AdminCreateEditNewsScreen(),
    ),
    GoRoute(
      path: '/news/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdminNewsDetailScreen(newsId: id);
      },
    ),
    GoRoute(
      path: '/news/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdminCreateEditNewsScreen(newsId: id);
      },
    ),
    GoRoute(
      path: RouterPath.allActivities,
      builder: (context, state) => const AdminAllActivitiesScreen(),
    ),
  ],
);
