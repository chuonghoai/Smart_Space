import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/mobile/admin_board/mobile_admin_board_view.dart';
import 'package:smartspace_admin/ui/screen/admin_board/web_admin_board_view.dart';

/// Hội đồng quản trị — quản lý tài khoản quản trị viên (responsive router).
class AdminBoardScreen extends StatelessWidget {
  const AdminBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: kIsWeb ? const WebAdminBoardView() : const MobileAdminBoardView(),
    );
  }
}
