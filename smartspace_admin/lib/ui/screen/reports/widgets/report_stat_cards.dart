import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ReportStatCards extends ConsumerWidget {
  const ReportStatCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statsAsync = ref.watch(reportStatisticsProvider);

    return statsAsync.when(
      data: (stats) {
        final items = [
          _CardData(l10n.totalReports, stats.total.toString(),
              Icons.assessment_outlined, Colors.blue),
          _CardData(l10n.pendingReports, stats.pending.toString(),
              Icons.hourglass_top_outlined, Colors.orange),
          _CardData(l10n.processingReportsLabel, stats.processing.toString(),
              Icons.autorenew_rounded, Colors.teal),
          _CardData(l10n.resolvedReports, stats.resolved.toString(),
              Icons.check_circle_outline, Colors.green),
          _CardData(l10n.rejectedReports, stats.rejected.toString(),
              Icons.cancel_outlined, Colors.red),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (constraints.maxWidth >= 1000) {
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
              itemBuilder: (context, index) => _buildCard(theme, items[index]),
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

  Widget _buildCard(ThemeData theme, _CardData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: data.color.withValues(alpha: 0.12),
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CardData(this.label, this.value, this.icon, this.color);
}
