import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/home/models/admin_overview_model.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';

class SmartAlertsSection extends ConsumerWidget {
  final AdminOverviewModel overview;
  final bool isDesktop;

  const SmartAlertsSection({
    super.key,
    required this.overview,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numFmt = NumberFormat('#,##0.#', locale);

    final spike = overview.volumeSpike;
    final alerts = <_AlertEntry>[
      if (spike != null && spike.isSpike)
        _AlertEntry(
          icon: Icons.trending_up_rounded,
          color: cs.error,
          title: l10n.volumeSpikeTitle,
          subtitle: l10n.volumeSpikeSubtitle(
            spike.todayCount,
            numFmt.format(spike.baselineAvg14d),
          ),
          badge: l10n.volumeSpikeZScoreBadge(numFmt.format(spike.zScore)),
          onTap: () {
            ref.read(reportFilterProvider.notifier).state =
                const ReportFilter(page: 1);
            context.go(RouterPath.reportDashboard);
          },
        ),
      if (overview.atRiskCount > 0)
        _AlertEntry(
          icon: Icons.schedule_rounded,
          color: semantic.warning,
          title: l10n.slaAtRiskTitle,
          subtitle: l10n.slaAtRiskSubtitle(
            overview.pendingAtRiskCount,
            overview.processingAtRiskCount,
          ),
          badge: overview.atRiskCount.toString(),
          onTap: () {
            ref.read(reportFilterProvider.notifier).state =
                const ReportFilter(page: 1, atRiskOnly: true);
            context.go(RouterPath.reportDashboard);
          },
        ),
      if (overview.overloadedStaffCount > 0)
        _AlertEntry(
          icon: Icons.manage_accounts_outlined,
          color: cs.error,
          title: l10n.overloadedStaffTitle,
          subtitle: l10n.overloadedStaffSubtitle(overview.overloadedStaffCount),
          badge: overview.overloadedStaffCount.toString(),
          onTap: () => context.go(RouterPath.staffManagement),
        ),
      if (overview.pendingOver24hCount > 0)
        _AlertEntry(
          icon: Icons.hourglass_bottom_rounded,
          color: semantic.info,
          title: l10n.pendingOver24hTitle,
          subtitle: l10n.pendingOver24hSubtitle(overview.pendingOver24hCount),
          badge: overview.pendingOver24hCount.toString(),
          onTap: () {
            ref.read(reportFilterProvider.notifier).state =
                const ReportFilter(page: 1, status: 'pending');
            context.go(RouterPath.reportDashboard);
          },
        ),
    ];

    final alertsCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.smartAlertsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: semantic.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: semantic.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: semantic.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.smartAlertsAllHealthy,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < alerts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _AlertRow(entry: alerts[i]),
                ],
              ],
            ),
        ],
      ),
    );

    final pulseCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: _Pulse7dChart(
        items: overview.pulse7Days,
        theme: theme,
        l10n: l10n,
        semantic: semantic,
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: alertsCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: pulseCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        alertsCard,
        const SizedBox(height: 14),
        pulseCard,
      ],
    );
  }
}

class _AlertEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _AlertEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertEntry entry;

  const _AlertRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: entry.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(entry.icon, size: 18, color: entry.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: entry.color,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pulse7dChart extends StatelessWidget {
  final List<DailyPulseItem> items;
  final ThemeData theme;
  final AppLocalizations l10n;
  final AppSemanticColors semantic;

  const _Pulse7dChart({
    required this.items,
    required this.theme,
    required this.l10n,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final maxVal = items.isEmpty
        ? 4.0
        : items
            .expand((e) => [e.inflow, e.outflow])
            .fold<int>(0, (m, v) => v > m ? v : m)
            .toDouble();
    final maxY = (maxVal * 1.25).ceilToDouble().clamp(4.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.pulse7dTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            _LegendDot(color: cs.primary, label: l10n.pulseInflowLabel),
            const SizedBox(width: 10),
            _LegendDot(
                color: semantic.success, label: l10n.pulseOutflowLabel),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 146,
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.noData,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: (maxY / 4)
                              .ceilToDouble()
                              .clamp(1, double.infinity),
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
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
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= items.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                items[idx].date,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < items.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 3,
                          barRods: [
                            BarChartRodData(
                              toY: items[i].inflow.toDouble(),
                              width: 7,
                              color: cs.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                            BarChartRodData(
                              toY: items[i].outflow.toDouble(),
                              width: 7,
                              color: semantic.success,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
