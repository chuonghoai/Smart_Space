import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/mobile/auth/forgot_password/forgot_password_screen.dart';
import 'package:smartspace_admin/ui/responsive/responsive_layout.dart';
import 'package:smartspace_admin/ui/web/auth/forgot_password_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileForgotPasswordScreen(),
      web: WebForgotPasswordScreen(),
    );
  }
}
