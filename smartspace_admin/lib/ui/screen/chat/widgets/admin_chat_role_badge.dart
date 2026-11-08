import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class AdminChatRoleBadge extends StatelessWidget {
  final String? role;
  final String? position;
  final bool isCompact;

  const AdminChatRoleBadge({
    super.key,
    required this.role,
    this.position,
    this.isCompact = false,
  });

  Widget _buildPill({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Border? border,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final r = role?.toLowerCase() ?? '';

    if (r == 'admin') {
      return _buildPill(
        theme: theme,
        label: l10n.filterRoleAdmin,
        icon: Icons.admin_panel_settings_outlined,
        bgColor: theme.colorScheme.tertiaryContainer,
        textColor: theme.colorScheme.onTertiaryContainer,
      );
    } else if (r == 'staff') {
      final pos = (position != null && position!.trim().isNotEmpty)
          ? position!.trim()
          : l10n.staffNoPosition;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Role Badge "Nhân viên"
          _buildPill(
            theme: theme,
            label: l10n.filterRoleStaff,
            icon: Icons.badge_outlined,
            bgColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            textColor: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          // 2. Separate Position Badge
          Flexible(
            child: _buildPill(
              theme: theme,
              label: pos,
              icon: Icons.work_outline_rounded,
              bgColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              textColor: theme.colorScheme.onSurfaceVariant,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
          ),
        ],
      );
    } else {
      // Resident / client
      return _buildPill(
        theme: theme,
        label: l10n.filterRoleClient,
        icon: Icons.person_outline_rounded,
        bgColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        textColor: theme.colorScheme.onSecondaryContainer,
      );
    }
  }
}
