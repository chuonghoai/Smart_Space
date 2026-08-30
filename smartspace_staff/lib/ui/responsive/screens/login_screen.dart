import 'package:flutter/material.dart';
import 'package:smartspace_staff/ui/mobile/login_screen.dart';
import 'package:smartspace_staff/ui/responsive/responsive_layout.dart';
import 'package:smartspace_staff/ui/web/login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileLoginScreen(),
      web: WebLoginScreen(),
    );
  }
}
