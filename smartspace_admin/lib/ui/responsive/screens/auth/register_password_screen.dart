import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/mobile/auth/register/register_password_screen.dart';
import 'package:smartspace_admin/ui/responsive/responsive_layout.dart';
import 'package:smartspace_admin/ui/web/auth/register_password_screen.dart';

class RegisterPasswordScreen extends StatelessWidget {
  const RegisterPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileRegisterPasswordScreen(),
      web: WebRegisterPasswordScreen(),
    );
  }
}
