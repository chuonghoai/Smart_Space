import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

/// Color legend overlay for the map — shows status→color mapping.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = [
      (reportStatusColor(context, 'pending'), l10n.reportStatusPending),
      (reportStatusColor(context, 'processing'), l10n.reportStatusProcessing),
      (reportStatusColor(context, 'processed'), l10n.reportStatusProcessed),
      (reportStatusColor(context, 'rejected'), l10n.reportStatusRejected),
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
