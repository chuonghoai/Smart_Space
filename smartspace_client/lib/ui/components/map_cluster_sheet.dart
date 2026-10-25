import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_time_format.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

/// Bottom sheet liệt kê các report trong một cluster không thể tách thêm
/// bằng zoom (trùng/sát toạ độ).
class MapClusterSheet extends StatelessWidget {
  final List<ReportModel> reports;
  final void Function(ReportModel report) onReportTap;

  const MapClusterSheet({
    super.key,
    required this.reports,
    required this.onReportTap,
  });

  /// Nguy hiểm nhất trước (critical → high → medium → low → chưa đánh giá), rồi mới nhất trước.
  static List<ReportModel> sortForCluster(List<ReportModel> reports) {
    int rank(EReportSeverity? severity) => switch (severity) {
          EReportSeverity.critical => 0,
          EReportSeverity.high => 1,
          EReportSeverity.medium => 2,
          EReportSeverity.low => 3,
          null => 4,
        };
    return [...reports]..sort((a, b) {
        final bySeverity = rank(a.severity).compareTo(rank(b.severity));
        return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sorted = sortForCluster(reports);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mapClusterReportsTitle(sorted.length),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.mapClusterSortHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 92,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final report = sorted[index];
                    return _ClusterReportTile(
                      report: report,
                      onTap: () => onReportTap(report),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClusterReportTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _ClusterReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = report.status.getColor(context);
    final severity = report.severity;
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _Thumbnail(imageUrl: report.imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${report.status.getLocalizedText(l10n)} · ${formatReportTimeAgo(report.createdAt, l10n)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (severity != null && report.isDangerous) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  severity.getLocalizedText(l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String imageUrl;

  const _Thumbnail({required this.imageUrl});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheSize = (_size * MediaQuery.of(context).devicePixelRatio).round();
    final placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.photo_camera_outlined,
        size: 22,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _size,
        height: _size,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              )
            : placeholder,
      ),
    );
  }
}
