import 'package:flutter/material.dart';
import 'package:smartspace_staff/ui/mobile/components/sidebar.dart';
import 'package:smartspace_staff/ui/mobile/components/top_bar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? customAppBar;
  final bool showDrawer;

  const AppLayout({
    super.key,
    required this.child,
    this.customAppBar,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar ?? const TopBar(),
      drawer: showDrawer ? const Sidebar() : null,
      body: child,
    );
  }
}
