import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/settings/manage_devices_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/settings/manage_devices_screen.dart';

class ManageDevicesScreen extends StatelessWidget {
  const ManageDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileManageDevicesScreen(),
      web: WebManageDevicesScreen(),
    );
  }
}
