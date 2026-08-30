import 'package:flutter/material.dart';
import 'package:smartspace_staff/ui/mobile/auth/register/register_password_screen.dart';
import 'package:smartspace_staff/ui/responsive/responsive_layout.dart';
import 'package:smartspace_staff/ui/web/auth/register_password_screen.dart';

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
