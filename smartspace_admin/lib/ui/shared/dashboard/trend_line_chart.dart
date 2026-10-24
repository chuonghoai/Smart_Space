import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Một đường dữ liệu trên [TrendLineChart]. [values] cùng độ dài với `dates`.
class TrendSeries {
  final String label;
  final Color color;
  final List<int> values;

  /// Tô vùng dưới đường (chỉ nên bật cho series chính).
  final bool showArea;

  const TrendSeries({
    required this.label,
    required this.color,
    required this.values,
    this.showArea = false,
  });
}

/// Biểu đồ xu hướng theo thời gian. Mỗi điểm là 1 bucket bắt đầu tại `dates[i]`
/// (daily: ngày, weekly: thứ Hai, monthly: ngày 1). Hiển thị legend khi có > 1 series.
class TrendLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final String period;
  final List<TrendSeries> series;

  /// Nội dung tooltip cho 1 giá trị, vd: "5 người dùng mới".
  final String Function(TrendSeries series, int value) tooltipValue;

  const TrendLineChart({
    super.key,
    required this.dates,
    required this.period,
    required this.series,
    required this.tooltipValue,
  });

  String _axisLabel(DateTime date) => switch (period) {
    'monthly' => DateFormat('MM/yy').format(date),
    _ => DateFormat('dd/MM').format(date),
  };

  String _tooltipLabel(AppLocalizations l10n, DateTime date) =>
      switch (period) {
        'weekly' => l10n.weekOf(DateFormat('dd/MM/yyyy').format(date)),
        'monthly' => DateFormat('MM/yyyy').format(date),
        _ => DateFormat('dd/MM/yyyy').format(date),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final chart = _buildChart(theme, l10n);
    if (series.length <= 1) return chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [for (final s in series) _LegendItem(series: s)],
        ),
        const SizedBox(height: 12),
        Expanded(child: chart),
      ],
    );
  }

  Widget _buildChart(ThemeData theme, AppLocalizations l10n) {
    final maxCount = series
        .expand((s) => s.values)
        .fold<int>(0, math.max)
        .toDouble();
    // Trục Y luôn có ít nhất 4 vạch nguyên
    final yInterval = math.max(1, (maxCount / 4).ceil()).toDouble();
    final maxY = yInterval * 4 + (maxCount >= yInterval * 4 ? yInterval : 0);
    // Tối đa ~7 nhãn trục X để không chồng chữ
    final labelEvery = math.max(1, (dates.length / 7).ceil());
    final showDots = dates.length <= 14;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if ((value - value.round()).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                final idx = value.round();
                final isLast = idx == dates.length - 1;
                if (idx < 0 ||
                    idx >= dates.length ||
                    (idx % labelEvery != 0 && !isLast)) {
                  return const SizedBox.shrink();
                }
                // Bỏ nhãn kế cuối nếu quá sát nhãn cuối
                if (!isLast &&
                    labelEvery > 1 &&
                    dates.length - 1 - idx < labelEvery / 2) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _axisLabel(dates[idx]),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: [
                for (var i = 0; i < s.values.length; i++)
                  FlSpot(i.toDouble(), s.values[i].toDouble()),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              curveSmoothness: 0.25,
              color: s.color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 3,
                  color: s.color,
                  strokeWidth: 1.5,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: s.showArea,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    s.color.withValues(alpha: 0.18),
                    s.color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) {
              // Nhãn thời gian chỉ hiện 1 lần ở dòng đầu
              return [
                for (var i = 0; i < spots.length; i++)
                  LineTooltipItem(
                    i == 0
                        ? '${_tooltipLabel(l10n, dates[spots[i].x.toInt()])}\n'
                        : '',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: tooltipValue(
                          series[spots[i].barIndex],
                          spots[i].y.toInt(),
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ];
            },
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final TrendSeries series;
  const _LegendItem({required this.series});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: series.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          series.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
