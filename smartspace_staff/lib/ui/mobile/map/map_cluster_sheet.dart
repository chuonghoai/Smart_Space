import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';
import 'package:mobile_shared/util/distance_formatter.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

/// Bottom sheet liệt kê việc trong một cluster không thể tách thêm bằng zoom
/// (trùng/sát toạ độ). Có GPS → gần nhất trước; không có → nguy hiểm trước, mới nhất trước.
class MapClusterSheet extends StatelessWidget {
  final List<ReportModel> reports;
  final void Function(ReportModel report) onReportTap;
  final void Function(ReportModel report) onOpenInMaps;

  const MapClusterSheet({
    super.key,
    required this.reports,
    required this.onReportTap,
    required this.onOpenInMaps,
  });

  static bool hasDistances(List<ReportModel> reports) =>
      reports.isNotEmpty && reports.every((r) => r.distanceInMeters != null);

  static List<ReportModel> sortForCluster(List<ReportModel> reports) {
    final byDistance = hasDistances(reports);
    int rank(ReportSeverity severity) => switch (severity) {
          ReportSeverity.critical => 0,
          ReportSeverity.high => 1,
          ReportSeverity.medium => 2,
          ReportSeverity.low => 3,
          ReportSeverity.unknown => 4,
        };
    return [...reports]..sort((a, b) {
        if (byDistance) return a.distanceInMeters!.compareTo(b.distanceInMeters!);
        final bySeverity = rank(a.severity).compareTo(rank(b.severity));
        return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sorted = sortForCluster(reports);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
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
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDistances(sorted) ? l10n.mapClusterSortNearest : l10n.mapClusterSortHint,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant),
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
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final report = sorted[index];
                    return _ClusterReportTile(
                      report: report,
                      onTap: () => onReportTap(report),
                      onOpenInMaps: () => onOpenInMaps(report),
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
  final VoidCallback onOpenInMaps;

  const _ClusterReportTile({
    required this.report,
    required this.onTap,
    required this.onOpenInMaps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final distance = report.distanceInMeters;
    final metaStyle = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);

    final meta = [
      report.needsRehandling ? l10n.rehandlingBadge : report.status.getLocalizedText(l10n),
      if (distance != null) DistanceFormatter.format(distance, SharedLocalizations.of(context)!),
    ].join(' · ');
    final dotColor = report.needsRehandling
        ? AppSemanticColors.of(context).warning
        : report.isDangerous
            ? cs.error
            : report.status.getColor(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
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
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          meta,
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
            // Vùng chạm 48dp: tìm đường tới hiện trường mà không cần mở chi tiết
            IconButton(
              tooltip: l10n.openInGoogleMaps,
              onPressed: onOpenInMaps,
              icon: Icon(Icons.directions_outlined, color: cs.primary),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
    final cs = Theme.of(context).colorScheme;
    final cacheSize = (_size * MediaQuery.of(context).devicePixelRatio).round();
    final placeholder = Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.photo_camera_outlined,
        size: 22,
        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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
                loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
              )
            : placeholder,
      ),
    );
  }
}
