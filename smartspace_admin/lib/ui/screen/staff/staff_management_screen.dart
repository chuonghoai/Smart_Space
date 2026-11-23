import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smartspace_admin/features/staff/models/staff_model.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/mobile/staff/mobile_staff_view.dart';
import 'package:smartspace_admin/ui/screen/staff/web_staff_view.dart';

/// Responsive router
class StaffManagementScreen extends StatelessWidget {
  final String? initialStaffId;
  final StaffModel? initialStaff;

  const StaffManagementScreen({
    super.key,
    this.initialStaffId,
    this.initialStaff,
  });

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: kIsWeb
          ? WebStaffView(
              initialStaffId: initialStaffId,
              initialStaff: initialStaff,
            )
          : MobileStaffView(
              initialStaffId: initialStaffId,
              initialStaff: initialStaff,
            ),
    );
  }
}
