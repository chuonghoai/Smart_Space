import 'package:flutter/material.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

class MapDensityLegend extends StatelessWidget {
  const MapDensityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.92),
      elevation: 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 5),
                Text(
                  l10n.densityLegendTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: const Color(0xFF22C55E),
              label: l10n.densityLow,
              colorScheme: colorScheme,
              textTheme: theme.textTheme,
            ),
            const SizedBox(height: 5),
            _LegendItem(
              color: const Color(0xFFF59E0B),
              label: l10n.densityMedium,
              colorScheme: colorScheme,
              textTheme: theme.textTheme,
            ),
            const SizedBox(height: 5),
            _LegendItem(
              color: const Color(0xFFEF4444),
              label: l10n.densityHigh,
              colorScheme: colorScheme,
              textTheme: theme.textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

