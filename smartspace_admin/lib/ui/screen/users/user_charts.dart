import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/features/users/models/user_statistics_model.dart';
import 'package:smartspace_admin/features/users/models/user_trend_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/users/user_shared_widgets.dart';

// Chart 1: Xu hướng đăng ký người dùng mới (Line/Area)

class UserRegistrationTrendChart extends ConsumerStatefulWidget {
  final double chartHeight;
  const UserRegistrationTrendChart({super.key, this.chartHeight = 220});

  @override
  ConsumerState<UserRegistrationTrendChart> createState() =>
      _UserRegistrationTrendChartState();
}

class _UserRegistrationTrendChartState
    extends ConsumerState<UserRegistrationTrendChart> {
  String _period = 'daily';

  String _axisLabel(DateTime date) => switch (_period) {
    'monthly' => DateFormat('MM/yy').format(date),
    _ => DateFormat('dd/MM').format(date),
  };

  String _tooltipLabel(AppLocalizations l10n, DateTime date) =>
      switch (_period) {
        'weekly' => l10n.weekOf(DateFormat('dd/MM/yyyy').format(date)),
        'monthly' => DateFormat('MM/yyyy').format(date),
        _ => DateFormat('dd/MM/yyyy').format(date),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trendAsync = ref.watch(userTrendProvider(_period));

    final periods = {
      'daily': l10n.daily,
      'weekly': l10n.weekly,
      'monthly': l10n.monthly,
    };

    return _ChartCard(
      title: l10n.registrationTrend,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _period,
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            items: periods.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (selected) {
              if (selected != null) setState(() => _period = selected);
            },
          ),
        ),
      ),
      child: SizedBox(
        height: widget.chartHeight,
        child: trendAsync.when(
          data: (items) => items.isEmpty
              ? Center(
                  child: Text(l10n.noData, style: theme.textTheme.bodySmall),
                )
              : _buildChart(theme, l10n, items),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(userTrendProvider(_period)),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    AppLocalizations l10n,
    List<UserTrendItem> items,
  ) {
    final maxCount = items.map((e) => e.count).reduce(math.max).toDouble();
    // Trục Y luôn có ít nhất 4 vạch nguyên
    final yInterval = math.max(1, (maxCount / 4).ceil()).toDouble();
    final maxY = yInterval * 4 + (maxCount >= yInterval * 4 ? yInterval : 0);
    // Tối đa ~7 nhãn trục X để không chồng chữ
    final labelEvery = math.max(1, (items.length / 7).ceil());
    final showDots = items.length <= 14;
    final primary = theme.colorScheme.primary;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (items.length - 1).toDouble(),
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
                final isLast = idx == items.length - 1;
                if (idx < 0 ||
                    idx >= items.length ||
                    (idx % labelEvery != 0 && !isLast)) {
                  return const SizedBox.shrink();
                }
                // Bỏ nhãn kế cuối nếu quá sát nhãn cuối
                if (!isLast &&
                    labelEvery > 1 &&
                    items.length - 1 - idx < labelEvery / 2) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _axisLabel(items[idx].date),
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
          LineChartBarData(
            spots: [
              for (var i = 0; i < items.length; i++)
                FlSpot(i.toDouble(), items[i].count.toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.25,
            color: primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: primary,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => spots.map((spot) {
              final item = items[spot.x.toInt()];
              return LineTooltipItem(
                '${_tooltipLabel(l10n, item.date)}\n',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface.withValues(
                    alpha: 0.8,
                  ),
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: l10n.newUsersCount(item.count),
                    style: TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Chart 2: Top người đóng góp — thanh ngang xếp hạng, bấm để xem chi tiết

class TopContributorsChart extends ConsumerWidget {
  final ValueChanged<String> onUserTap;
  const TopContributorsChart({super.key, required this.onUserTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statsAsync = ref.watch(userStatisticsProvider);

    return _ChartCard(
      title: l10n.topContributors,
      subtitle: l10n.anonymousReportsExcluded,
      child: statsAsync.when(
        data: (stats) => stats.topReporters.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    l10n.noData,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : _buildList(context, theme, l10n, stats.topReporters),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(userStatisticsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    List<TopReporterItem> items,
  ) {
    final maxCount = items.map((e) => e.reportCount).reduce(math.max);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          InkWell(
            onTap: () => onUserTap(items[i].userId),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  UserAvatar(
                    avatarUrl: items[i].avatarUrl,
                    name: items[i].fullName,
                    radius: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxCount == 0
                                ? 0
                                : items[i].reportCount / maxCount,
                            minHeight: 6,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${items[i].reportCount}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _ChartCard({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
