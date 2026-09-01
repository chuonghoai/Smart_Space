import 'package:flutter/material.dart';
import 'package:smartspace_client/ui/mobile/settings/edit_profile_screen.dart';
import 'package:smartspace_client/ui/responsive/responsive_layout.dart';
import 'package:smartspace_client/ui/web/settings/edit_profile_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileEditProfileScreen(),
      web: WebEditProfileScreen(),
    );
  }
}
