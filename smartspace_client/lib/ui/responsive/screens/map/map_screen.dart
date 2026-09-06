import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/map/map_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/map/web_map_screen_stub.dart'
    if (dart.library.js_interop) 'package:smartspace_client/ui/web/map/map_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileMapScreen(),
      web: WebMapScreen(),
    );
  }
}
