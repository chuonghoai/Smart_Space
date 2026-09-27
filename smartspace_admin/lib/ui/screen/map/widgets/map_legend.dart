import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Color legend overlay for the map — shows status→color mapping.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      (isDark ? const Color(0xFFEF5350) : cs.error, l10n.reportStatusPending),
      (isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825), l10n.reportStatusProcessing),
      (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32), l10n.reportStatusProcessed),
      (cs.outline, l10n.reportStatusRejected),
    ];

    return Positioned(
      bottom: 16,
      left: 12,
      child: Card(
        color: cs.surface.withValues(alpha: 0.92),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (color, label) in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
