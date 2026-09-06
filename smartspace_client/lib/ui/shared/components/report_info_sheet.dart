import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Bottom sheet hiển thị thông tin report khi tap marker
class ReportInfoSheet extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onViewDetail;

  const ReportInfoSheet({
    super.key,
    required this.report,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _StatusChip(status: report.status, colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            report.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Distance
          if (report.distanceInMeters != null)
            Row(
              children: [
                Icon(Icons.place,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  report.distanceInMeters! < 1000
                      ? '${report.distanceInMeters!.round()} m'
                      : '${(report.distanceInMeters! / 1000).toStringAsFixed(1)} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onViewDetail,
              icon: const Icon(Icons.info_outline),
              label: Text(l10n.viewDetail),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReportStatus status;
  final ColorScheme colorScheme;

  const _StatusChip({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;

    switch (status) {
      case ReportStatus.processed:
        chipColor = Colors.green;
        label = 'Processed';
      case ReportStatus.processing:
        chipColor = Colors.orange;
        label = 'Processing';
      case ReportStatus.pending:
        chipColor = Colors.blue;
        label = 'Pending';
      case ReportStatus.rejected:
        chipColor = Colors.red;
        label = 'Rejected';
      case ReportStatus.unknown:
        chipColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
