import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/auth/login/login_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/auth/login_screen.dart';

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
