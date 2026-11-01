import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

/// Bottom sheet hiển thị thông tin report khi tap marker
class ReportInfoSheet extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onViewDetail;
  final VoidCallback? onOpenInMaps;

  const ReportInfoSheet({
    super.key,
    required this.report,
    this.onViewDetail,
    this.onOpenInMaps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
                // Thumbnail ảnh report
                _ReportThumbnail(
                  imageUrl: report.imageUrl,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 14),

                // Info bên phải thumbnail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status chip (+ huy hiệu xử lý lại)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusChip(status: report.status),
                          if (report.needsRehandling)
                            _Badge(
                              label: l10n.rehandlingBadge,
                              color: AppSemanticColors.of(context).warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        report.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        report.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Meta info row: Distance + Time
                      Row(
                        children: [
                          // Distance
                          if (report.distanceInMeters != null) ...[
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDistance(report.distanceInMeters!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Time
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(report.createdAt, l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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

          // Hành động: tìm đường tới hiện trường / mở chi tiết để xử lý
          if (onOpenInMaps != null || onViewDetail != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  if (onOpenInMaps != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenInMaps,
                        icon: const Icon(Icons.directions_outlined, size: 20),
                        label: Text(l10n.mapGetDirections, maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                  if (onOpenInMaps != null && onViewDetail != null) const SizedBox(width: 12),
                  if (onViewDetail != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: onViewDetail,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: Text(l10n.viewDetail, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatTime(DateTime createdAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.minuteAgo}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${l10n.hourAgo}';
    } else {
      return '${diff.inDays} ${l10n.dayAgo}';
    }
  }
}

/// Thumbnail ảnh report với fallback icon
class _ReportThumbnail extends StatelessWidget {
  final String imageUrl;
  final ColorScheme colorScheme;

  const _ReportThumbnail({
    required this.imageUrl,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 100,
        height: 100,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoading();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.photo_camera_outlined,
        size: 32,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Status chip — màu/nhãn dùng chung [ReportStatusExt] như các màn khác của app Staff.
class _StatusChip extends StatelessWidget {
  final ReportStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Badge(label: status.getLocalizedText(l10n), color: status.getColor(context));
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
