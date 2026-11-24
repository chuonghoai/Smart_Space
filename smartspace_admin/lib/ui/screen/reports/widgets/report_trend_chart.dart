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
    final cs = theme.colorScheme;
    final trendAsync = ref.watch(reportTrendDataProvider(_selectedPeriod));

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
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.reportTrend,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      trendAsync.maybeWhen(
                        data: (trendData) {
                          if (_selectedPeriod != 'daily') {
                            return const SizedBox.shrink();
                          }
                          if (trendData.insufficientData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.trendInsufficientBaseline,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          if (trendData.anomalyCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.trendAnomalyCountBadge(
                                    trendData.anomalyCount),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      items: periods.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          setState(() => _selectedPeriod = selected);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: 200,
              child: trendAsync.when(
                data: (trendData) {
                  final items = trendData.items;
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
                  final maxBaseline = items
                      .map((e) => e.baselineAvg ?? 0.0)
                      .reduce((a, b) => a > b ? a : b);
                  final peak = maxCount > maxBaseline ? maxCount : maxBaseline;
                  final maxY =
                      (peak * 1.2).ceilToDouble().clamp(1.0, double.infinity);

                  final hasBaselineSeries = _selectedPeriod == 'daily' &&
                      items.any((e) => e.baselineAvg != null);
                  final labelStep = items.length > 15 ? 4 : 1;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
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
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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
                              if ((value - value.round()).abs() > 0.01) {
                                return const SizedBox();
                              }
                              final idx = value.round();
                              if (idx < 0 || idx >= items.length) {
                                return const SizedBox();
                              }
                              if (labelStep > 1 &&
                                  idx % labelStep != 0 &&
                                  idx != items.length - 1) {
                                return const SizedBox();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  items[idx].label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
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
                        if (hasBaselineSeries)
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < items.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  items[i].baselineAvg ?? 0.0,
                                ),
                            ],
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                            barWidth: 1.5,
                            dashArray: const [5, 4],
                            dotData: const FlDotData(show: false),
                          ),
                        LineChartBarData(
                          spots: List.generate(
                            items.length,
                            (i) => FlSpot(i.toDouble(), items[i].count.toDouble()),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: cs.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, pct, bar, idx) {
                              final isAnomaly = idx >= 0 &&
                                  idx < items.length &&
                                  items[idx].anomaly;
                              return FlDotCirclePainter(
                                radius: isAnomaly ? 5.0 : 2.5,
                                color: isAnomaly ? cs.error : cs.primary,
                                strokeWidth: isAnomaly ? 2 : 1.5,
                                strokeColor: cs.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipColor: (_) => cs.inverseSurface,
                          getTooltipItems: (spots) => spots.map((spot) {
                            final idx = spot.x.toInt();
                            if (idx < 0 || idx >= items.length) {
                              return null;
                            }
                            final item = items[idx];
                            final isBaselineBar = hasBaselineSeries && spot.barIndex == 0;
                            if (isBaselineBar) {
                              return LineTooltipItem(
                                '${l10n.trendBaselineLabel}: ${spot.y.toStringAsFixed(1)}',
                                TextStyle(
                                  color: cs.onInverseSurface.withValues(alpha: 0.85),
                                  fontSize: 11,
                                ),
                              );
                            }
                            final anomalyTag = item.anomaly ? ' [${l10n.trendAnomalyBadge}]' : '';
                            return LineTooltipItem(
                              '${item.label}$anomalyTag\n${spot.y.toInt()} ${l10n.totalReports.toLowerCase()}',
                              TextStyle(
                                color: item.anomaly ? cs.errorContainer : cs.onInverseSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
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
