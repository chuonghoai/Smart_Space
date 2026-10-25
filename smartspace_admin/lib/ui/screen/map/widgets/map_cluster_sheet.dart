import 'package:flutter/material.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

/// Bottom sheet liệt kê các report trong một cluster không thể tách thêm
/// bằng zoom (trùng/sát toạ độ). Bấm một dòng → mở [MapReportSheet] (có nút phân công).
class MapClusterSheet extends StatelessWidget {
  final List<MapReportModel> reports;
  final void Function(MapReportModel report) onReportTap;

  const MapClusterSheet({
    super.key,
    required this.reports,
    required this.onReportTap,
  });

  /// Chờ xử lý trước (việc admin cần làm), rồi mới nhất trước.
  static List<MapReportModel> sortForCluster(List<MapReportModel> reports) {
    return [...reports]..sort((a, b) {
        if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null || bTime == null) return aTime == null ? 1 : -1;
        return bTime.compareTo(aTime);
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
                      l10n.mapClusterSortHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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
  final MapReportModel report;
  final VoidCallback onTap;

  const _ClusterReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (statusColor, statusLabel) = reportStatusStyle(context, l10n, report.status);
    final address = report.address;
    final metaStyle = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);

    final placeholder = Container(
      width: 56,
      height: 56,
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.photo_camera_outlined,
        size: 22,
        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (report.imageUrl ?? '').isEmpty
                  ? placeholder
                  : AppNetworkImage(
                      url: report.imageUrl,
                      width: 56,
                      height: 56,
                      errorWidget: placeholder,
                      placeholderWidget: placeholder,
                    ),
            ),
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
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          address == null || address.isEmpty
                              ? statusLabel
                              : '$statusLabel · $address',
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
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
