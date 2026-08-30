import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/web/components/sidebar.dart';
import 'package:smartspace_admin/ui/web/components/top_bar.dart';

class WebLayout extends StatelessWidget {
  final Widget child;

  const WebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const WebSidebar(),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Scaffold(appBar: const WebTopBar(), body: child),
          ),
        ],
      ),
    );
  }
}
