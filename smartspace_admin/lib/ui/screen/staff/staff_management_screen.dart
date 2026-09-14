import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/mobile/staff/mobile_staff_view.dart';
import 'package:smartspace_admin/ui/screen/staff/web_staff_view.dart';

/// Responsive router
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: kIsWeb ? const WebStaffView() : const MobileStaffView(),
    );
  }
}
