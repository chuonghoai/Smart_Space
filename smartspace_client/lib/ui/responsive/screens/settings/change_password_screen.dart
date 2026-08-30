import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/settings/change_password_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/settings/change_password_screen.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileChangePasswordScreen(),
      web: WebChangePasswordScreen(),
    );
  }
}
