import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ReportStatCards extends ConsumerWidget {
  const ReportStatCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(reportStatisticsProvider);
    final currentFilter = ref.watch(reportFilterProvider);

    return statsAsync.when(
      data: (stats) {
        final items = [
          _CardData(l10n.totalReports, stats.total.toString(),
              Icons.assessment_outlined, Colors.blue, null),
          _CardData(l10n.pendingReports, stats.pending.toString(),
              Icons.hourglass_top_outlined, Colors.orange, 'pending'),
          _CardData(l10n.processingReportsLabel, stats.processing.toString(),
              Icons.autorenew_rounded, Colors.teal, 'processing'),
          _CardData(l10n.resolvedReports, stats.resolved.toString(),
              Icons.check_circle_outline, Colors.green, 'processed'),
          _CardData(l10n.rejectedReports, stats.rejected.toString(),
              Icons.cancel_outlined, Colors.red, 'rejected'),
          _CardData(
            l10n.rehandlingBadge,
            stats.rehandling.toString(),
            Icons.refresh_rounded,
            isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
            'rehandling',
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 6;
            } else if (constraints.maxWidth >= 1000) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth >= 700) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 84,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = item.statusFilter == null
                    ? (currentFilter.status == null ||
                        currentFilter.status!.isEmpty)
                    : currentFilter.status == item.statusFilter;
                return _buildCard(theme, item, isActive, isDark, () {
                  if (item.statusFilter == null) {
                    ref.read(reportFilterProvider.notifier).state =
                        const ReportFilter(page: 1);
                  } else {
                    ref.read(reportFilterProvider.notifier).state =
                        const ReportFilter(page: 1)
                            .copyWith(status: item.statusFilter);
                  }
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Error: $e',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, _CardData data, bool isActive,
      bool isDark, VoidCallback onTap) {
    final borderColor = isActive
        ? data.color.withValues(alpha: isDark ? 0.6 : 0.45)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    final bgColor = isActive
        ? data.color.withValues(alpha: isDark ? 0.12 : 0.07)
        : theme.cardColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: isActive ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isActive ? data.color : theme.hintColor,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data.value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? data.color
                            : theme.colorScheme.onSurface,
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

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? statusFilter;
  const _CardData(
      this.label, this.value, this.icon, this.color, this.statusFilter);
}
