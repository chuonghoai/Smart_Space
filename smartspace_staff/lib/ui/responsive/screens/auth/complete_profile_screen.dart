import 'package:flutter/material.dart';
import 'package:smartspace_staff/ui/mobile/auth/register/complete_profile_screen.dart';
import 'package:smartspace_staff/ui/responsive/responsive_layout.dart';
import 'package:smartspace_staff/ui/web/auth/complete_profile_screen.dart';

class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileCompleteProfileScreen(),
      web: WebCompleteProfileScreen(),
    );
  }
}
