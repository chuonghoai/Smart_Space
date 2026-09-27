import 'package:flutter/material.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

/// Bottom sheet hiển thị thông tin report khi tap marker trên map.
/// Tham khảo thiết kế từ client ReportInfoSheet.
class MapReportSheet extends StatelessWidget {
  final MapReportModel report;
  final VoidCallback onViewDetail;
  final VoidCallback? onAssign;

  const MapReportSheet({
    super.key,
    required this.report,
    required this.onViewDetail,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brightness = theme.brightness;
    final statusColor = report.statusColorAdaptive(cs, brightness);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Main content: Thumbnail + Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: AppNetworkImage(
                      url: report.imageUrl,
                      width: 100,
                      height: 100,
                      errorWidget: Container(
                        width: 100,
                        height: 100,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 32,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(l10n, report.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        report.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Address
                      if (report.address != null &&
                          report.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          report.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Meta info row: Severity + Time
                      Row(
                        children: [
                          // Severity
                          if (report.severity != null) ...[
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              report.severity!.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Time
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(report.createdAt, l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.7),
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

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l10n.mapViewDetail),
                  ),
                ),
                if (onAssign != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAssign,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: Text(l10n.mapAssignStaff),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'pending' => l10n.reportStatusPending,
      'processing' => l10n.reportStatusProcessing,
      'processed' => l10n.reportStatusProcessed,
      'rejected' => l10n.reportStatusRejected,
      _ => l10n.reportStatusUnknown,
    };
  }

  String _formatTime(DateTime? createdAt, AppLocalizations l10n) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.minuteAgo}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${l10n.hourAgo}';
    } else {
      return '${diff.inDays} ${l10n.dayAgo}';
    }
  }
}
