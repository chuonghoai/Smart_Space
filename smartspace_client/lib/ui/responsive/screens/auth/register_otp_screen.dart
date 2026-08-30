import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/auth/register/register_otp_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/auth/register_otp_screen.dart';

class RegisterOtpScreen extends StatelessWidget {
  const RegisterOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileRegisterOtpScreen(),
      web: WebRegisterOtpScreen(),
    );
  }
}
