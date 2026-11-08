import 'package:flutter/material.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class ChatRoleBadge extends StatelessWidget {
  final String? role;
  final String? position;
  final bool isCompact;

  const ChatRoleBadge({
    super.key,
    required this.role,
    this.position,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final r = role?.toLowerCase() ?? '';

    String label;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (r == 'admin') {
      label = l10n.roleAdmin;
      bgColor = theme.colorScheme.tertiaryContainer;
      textColor = theme.colorScheme.onTertiaryContainer;
      icon = Icons.admin_panel_settings_outlined;
    } else if (r == 'staff') {
      final pos = (position != null && position!.trim().isNotEmpty)
          ? position!.trim()
          : l10n.staffNoPosition;
      label = isCompact ? l10n.roleStaff : '${l10n.roleStaff} • $pos';
      bgColor = theme.colorScheme.primaryContainer.withOpacity(0.7);
      textColor = theme.colorScheme.onPrimaryContainer;
      icon = Icons.badge_outlined;
    } else {
      // Default to resident / client
      label = l10n.roleClient;
      bgColor = theme.colorScheme.secondaryContainer.withOpacity(0.6);
      textColor = theme.colorScheme.onSecondaryContainer;
      icon = Icons.person_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 11 : 13, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

