import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsMetadataBar extends StatelessWidget {
  final String authorName;
  final DateTime? createdAt;
  final bool compact;

  const NewsMetadataBar({
    super.key,
    required this.authorName,
    required this.createdAt,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt!)
        : '--/--/----';
    final timeStr = createdAt != null
        ? DateFormat('HH:mm').format(createdAt!)
        : '--:--';

    final containerColor = isDark
        ? colorScheme.surfaceVariant.withOpacity(0.4)
        : colorScheme.surfaceVariant.withOpacity(0.5);
    final borderColor = colorScheme.outlineVariant.withOpacity(0.4);
    final iconColor = colorScheme.primary;
    final textColor = colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Wrap(
        spacing: compact ? 12 : 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Icon người tạo
          _buildItem(
            icon: Icons.person_outline,
            label: authorName.isNotEmpty ? authorName : 'Admin',
            iconColor: iconColor,
            textColor: textColor,
            theme: theme,
            compact: compact,
          ),
          // 2. Icon ngày tạo
          _buildItem(
            icon: Icons.calendar_today_outlined,
            label: dateStr,
            iconColor: iconColor,
            textColor: textColor,
            theme: theme,
            compact: compact,
          ),
          // 3. Icon thời gian tạo
          _buildItem(
            icon: Icons.access_time_outlined,
            label: timeStr,
            iconColor: iconColor,
            textColor: textColor,
            theme: theme,
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required ThemeData theme,
    required bool compact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 14 : 16,
          color: iconColor,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: (compact
                  ? theme.textTheme.labelSmall
                  : theme.textTheme.bodySmall)
              ?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
