import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MyReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const MyReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isRejected = report.status == ReportStatus.rejected;
    final canEdit = report.status == ReportStatus.pending;
    final canCancel = report.status == ReportStatus.pending;
    final hasActions = canEdit || canCancel;

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
                  width: 64,
                  height: 64,
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
                      // Title row with "My report" badge and 3-dots action button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    report.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.myReportBadge,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasActions)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') onEdit?.call();
                                  if (val == 'cancel') onCancel?.call();
                                },
                                itemBuilder: (ctx) => [
                                  if (canEdit)
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.editReport),
                                        ],
                                      ),
                                    ),
                                  if (canCancel)
                                    PopupMenuItem(
                                      value: 'cancel',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.cancel_outlined,
                                            size: 18,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.cancelReport,
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Address/Description mapping
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.description,
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
                          // Badges
                          Flexible(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (report.isReviewResolved == false)
                                  const _UnsatisfactoryBadge(),
                                _MyReportStatusBadge(status: report.status),
                              ],
                            ),
                          ),
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

class _UnsatisfactoryBadge extends StatelessWidget {
  const _UnsatisfactoryBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final badgeBg = isDark ? const Color(0xFF4A2800) : const Color(0xFFFFF3E0);
    final badgeColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.5 : 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            l10n.unsatisfactoryBadge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
