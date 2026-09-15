import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartspace_admin/features/staff/models/staff_chart_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

// Chart 1: Donut Chart — Trạng thái nhân sự (Active / Blocked)

class StaffStatusDonutChart extends StatelessWidget {
  final int activeCount;
  final int blockedCount;

  const StaffStatusDonutChart({
    super.key,
    required this.activeCount,
    required this.blockedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = activeCount + blockedCount;

    // Semantic colors từ design.md
    final activeColor = theme.brightness == Brightness.light
        ? const Color(0xFF2E7D32) // Success Light
        : const Color(0xFF66BB6A); // Success Dark
    final blockedColor = theme.colorScheme.error;

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
              l10n.staffStatusChart,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: total == 0
                  ? Center(
                      child: Text(
                        l10n.noWorkloadData,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 48,
                            sections: [
                              PieChartSectionData(
                                value: activeCount.toDouble(),
                                color: activeColor,
                                title: activeCount > 0 ? '$activeCount' : '',
                                titleStyle: theme.textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                radius: 30,
                              ),
                              PieChartSectionData(
                                value: blockedCount.toDouble(),
                                color: blockedColor,
                                title: blockedCount > 0 ? '$blockedCount' : '',
                                titleStyle: theme.textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                radius: 30,
                              ),
                            ],
                          ),
                        ),
                        // Tổng ở giữa donut
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.totalStaff,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: activeColor, label: l10n.activeStaff),
                const SizedBox(width: 20),
                _LegendDot(color: blockedColor, label: l10n.blockedStaff),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Chart 2: Bar Chart — Top nhân viên xử lý báo cáo

class StaffWorkloadBarChart extends StatelessWidget {
  final List<WorkloadItem> topWorkload;

  const StaffWorkloadBarChart({super.key, required this.topWorkload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (topWorkload.isEmpty) {
      return _buildEmptyCard(context, theme, l10n);
    }

    final maxCount = topWorkload
        .map((e) => e.processingCount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY = (maxCount * 1.3).ceilToDouble().clamp(1.0, double.infinity);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workloadChart,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 185,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (group, _, rod, __) {
                        final item = topWorkload[group.x];
                        return BarTooltipItem(
                          '${item.staffName}\n',
                          theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${item.processingCount} ${l10n.reportsProcessing}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onInverseSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (maxY / 4).ceilToDouble().clamp(1, 999),
                        getTitlesWidget: (value, meta) {
                          if (value != value.floorToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${value.toInt()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= topWorkload.length) {
                            return const SizedBox.shrink();
                          }
                          final name = topWorkload[index].staffName;
                          final parts = name.trim().split(' ');
                          // Lấy tên (phần cuối của họ tên)
                          final shortName = parts.isNotEmpty
                              ? parts.last.length > 7
                                    ? '${parts.last.substring(0, 6)}…'
                                    : parts.last
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              shortName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, 999),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(topWorkload.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: topWorkload[i].processingCount.toDouble(),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
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
              l10n.workloadChart,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noWorkloadData,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Widget phụ: Legend dot

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
