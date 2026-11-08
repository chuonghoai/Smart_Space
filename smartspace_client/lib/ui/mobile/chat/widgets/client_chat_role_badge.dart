import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class ClientChatRoleBadge extends StatelessWidget {
  final String? role;
  final bool isCompact;

  const ClientChatRoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final r = role?.toLowerCase() ?? '';

    if (r == 'admin') {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: isCompact ? 11 : 13,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.roleAdmin,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (r == 'staff') {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.badge_outlined,
              size: isCompact ? 11 : 13,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.roleStaff,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Never display resident badge or other roles
    return const SizedBox.shrink();
  }
}

