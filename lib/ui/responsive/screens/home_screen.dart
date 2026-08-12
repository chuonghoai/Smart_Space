import 'package:flutter/material.dart';
import 'package:smartspace_staff/ui/mobile/home_screen.dart';
import 'package:smartspace_staff/ui/responsive/responsive_layout.dart';
import 'package:smartspace_staff/ui/web/home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileHomeScreen(),
      web: WebHomeScreen(),
    );
  }
}
