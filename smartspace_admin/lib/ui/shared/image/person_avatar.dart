import 'package:flutter/material.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

/// Avatar người (user/staff) — ảnh mạng qua [AppNetworkImage], fallback chữ cái đầu.
class PersonAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const PersonAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return AppNetworkImage(
      url: avatarUrl,
      width: radius * 2,
      height: radius * 2,
      isCircle: true,
      errorWidget: initials,
    );
  }
}
