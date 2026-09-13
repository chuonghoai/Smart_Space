import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MyReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const MyReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = report.status == ReportStatus.rejected;

    return Opacity(
      opacity: isRejected ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: report.imageUrl.isNotEmpty
                      ? Image.network(
                          report.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image, color: theme.colorScheme.outline),
                        )
                      : Icon(Icons.image, color: theme.colorScheme.outline),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        report.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Address/Description mapping
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.description, // using description as proxy for address if address is not available in basic model
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Date and Status (Bottom Row)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Date / Time
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          // Status Badge
                          _MyReportStatusBadge(status: report.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyReportStatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _MyReportStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    Color chipColor;
    String label;

    switch (status) {
      case ReportStatus.processed:
        chipColor = Colors.green;
        label = l10n.reportStatusProcessed;
      case ReportStatus.processing:
        chipColor = Colors.orange;
        label = l10n.reportStatusProcessing;
      case ReportStatus.pending:
        chipColor = Colors.blue;
        label = l10n.reportStatusPending;
      case ReportStatus.rejected:
        chipColor = Colors.red;
        label = l10n.reportStatusRejected;
      case ReportStatus.unknown:
        chipColor = Colors.grey;
        label = l10n.reportStatusUnknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
