import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/mobile/users/mobile_user_view.dart';
import 'package:smartspace_admin/ui/screen/users/web_user_view.dart';

/// Responsive router
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: kIsWeb ? const WebUserView() : const MobileUserView(),
    );
  }
}
