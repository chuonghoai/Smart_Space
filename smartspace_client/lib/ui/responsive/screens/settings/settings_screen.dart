import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/settings/settings_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/settings/settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileSettingsScreen(),
      web: WebSettingsScreen(),
    );
  }
}
