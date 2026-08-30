import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_email_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/auth/register_email_screen.dart';

class RegisterEmailScreen extends StatelessWidget {
  const RegisterEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileRegisterEmailScreen(),
      web: WebRegisterEmailScreen(),
    );
  }
}
