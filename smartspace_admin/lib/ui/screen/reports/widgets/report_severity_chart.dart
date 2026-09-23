import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ReportSeverityChart extends ConsumerWidget {
  const ReportSeverityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statsAsync = ref.watch(reportStatisticsProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.severityDistribution,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) {
                final severity = stats.bySeverity;
                final sections = <_SeverityData>[
                  _SeverityData('Low', severity['low'] ?? 0, Colors.green),
                  _SeverityData('Medium', severity['medium'] ?? 0, Colors.orange),
                  _SeverityData('High', severity['high'] ?? 0, Colors.deepOrange),
                  _SeverityData('Critical', severity['critical'] ?? 0, Colors.red),
                ];
                final total = sections.fold(0, (sum, s) => sum + s.count);

                if (total == 0) {
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(l10n.noData,
                          style: theme.textTheme.bodySmall),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: sections
                                  .where((s) => s.count > 0)
                                  .map((s) => PieChartSectionData(
                                        value: s.count.toDouble(),
                                        color: s.color,
                                        title: '${s.count}',
                                        titleStyle:
                                            theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        radius: 30,
                                      ))
                                  .toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                l10n.totalReports,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: sections
                          .map((s) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: s.color),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(s.label,
                                      style: theme.textTheme.labelSmall),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityData {
  final String label;
  final int count;
  final Color color;
  const _SeverityData(this.label, this.count, this.color);
}
