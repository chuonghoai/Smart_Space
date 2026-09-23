import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ReportTrendChart extends ConsumerStatefulWidget {
  const ReportTrendChart({super.key});

  @override
  ConsumerState<ReportTrendChart> createState() => _ReportTrendChartState();
}

class _ReportTrendChartState extends ConsumerState<ReportTrendChart> {
  String _selectedPeriod = 'daily';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trendAsync = ref.watch(reportTrendProvider(_selectedPeriod));

    final periods = {
      'daily': l10n.daily,
      'weekly': l10n.weekly,
      'monthly': l10n.monthly,
    };

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
            // Header + Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.reportTrend,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                SegmentedButton<String>(
                  segments: periods.entries
                      .map((e) => ButtonSegment(
                            value: e.key,
                            label: Text(e.value,
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                  selected: {_selectedPeriod},
                  onSelectionChanged: (selected) =>
                      setState(() => _selectedPeriod = selected.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: 200,
              child: trendAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(l10n.noData,
                          style: theme.textTheme.bodySmall),
                    );
                  }

                  final maxCount = items
                      .map((e) => e.count)
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble();
                  final maxY =
                      (maxCount * 1.2).ceilToDouble().clamp(1.0, double.infinity);

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      // Mở rộng minX/maxX 0.5 mỗi bên → label không bị cắt
                      minX: -0.5,
                      maxX: items.length - 0.5,
                      minY: 0,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              // Chỉ render tại đúng vị trí số nguyên
                              // Khi minX=-0.5, fl_chart sinh ra -0.5, 0.5, 1.5...
                              // → cả -0.5 và 0.5 đều cho .toInt()=0 → label bị trùng
                              if ((value - value.round()).abs() > 0.01) {
                                return const SizedBox();
                              }
                              final idx = value.round();
                              if (idx < 0 || idx >= items.length) {
                                return const SizedBox();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  items[idx].label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            items.length,
                            (i) => FlSpot(i.toDouble(), items[i].count.toDouble()),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: theme.colorScheme.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) =>
                                FlDotCirclePainter(
                              radius: 3,
                              color: theme.colorScheme.primary,
                              strokeWidth: 1.5,
                              strokeColor: theme.colorScheme.surface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                          getTooltipItems: (spots) => spots
                              .map((spot) => LineTooltipItem(
                                    '${items[spot.x.toInt()].label}\n${spot.y.toInt()} ${l10n.totalReports.toLowerCase()}',
                                    TextStyle(
                                      color: theme.colorScheme.onInverseSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
