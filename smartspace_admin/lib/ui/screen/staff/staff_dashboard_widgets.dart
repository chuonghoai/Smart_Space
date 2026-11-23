import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_workload_badge.dart';
import 'package:smartspace_admin/ui/shared/dashboard/chart_card.dart';
import 'package:smartspace_admin/ui/shared/dashboard/kpi_card.dart';
import 'package:smartspace_admin/ui/shared/dashboard/ranked_bar_list.dart';
import 'package:smartspace_admin/ui/shared/dashboard/trend_line_chart.dart';

/// "45 phút" / "5,2 giờ" / "1,3 ngày" theo locale.
String formatResolutionDuration(BuildContext context, int minutes) {
  final l10n = AppLocalizations.of(context)!;
  final format = NumberFormat(
    '#,##0.#',
    Localizations.localeOf(context).toLanguageTag(),
  );
  if (minutes < 60) return l10n.durationMinutes('$minutes');
  if (minutes < 48 * 60) return l10n.durationHours(format.format(minutes / 60));
  return l10n.durationDays(format.format(minutes / (24 * 60)));
}

/// Bộ chọn tháng thống kê dùng chung cho Web & Mobile trong màn Quản lý nhân viên.
class StaffStatsMonthSelector extends ConsumerWidget {
  const StaffStatsMonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = ref.watch(staffStatisticsProvider).valueOrNull;
    final selected = ref.watch(selectedStaffStatsMonthProvider);
    final now = DateTime.now();

    final currentYear = selected?.year ?? stats?.selectedYear ?? now.year;
    final currentMonth = selected?.month ?? stats?.selectedMonth ?? now.month;

    final rawMonths = stats?.availableMonths ?? const <AvailableMonthItem>[];
    final items = <AvailableMonthItem>[...rawMonths];
    if (!items.any((m) => m.year == currentYear && m.month == currentMonth)) {
      items.insert(
        0,
        AvailableMonthItem(
          year: currentYear,
          month: currentMonth,
          label: '${currentMonth.toString().padLeft(2, '0')}/$currentYear',
        ),
      );
    }

    String encode(int year, int month) => '$year-$month';
    final selectedKey = encode(currentYear, currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.statsMonthLabel}: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKey,
              isDense: true,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              items: items
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: encode(m.year, m.month),
                      child: Text(
                        m.label,
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (key) {
                if (key == null) return;
                final parts = key.split('-');
                if (parts.length != 2) return;
                final y = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                if (y != null && m != null) {
                  ref.read(selectedStaffStatsMonthProvider.notifier).state = (
                    year: y,
                    month: m,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 4 KPI của màn Quản lý nhân viên.
class StaffKpiGrid extends ConsumerWidget {
  final bool compact;
  const StaffKpiGrid({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(staffStatisticsProvider);

    return statsAsync.when(
      data: (stats) => _buildGrid(context, l10n, stats),
      loading: () => _buildGrid(context, l10n, null),
      error: (_, _) => InlineErrorBanner(
        message: l10n.statisticsLoadFailed,
        onRetry: () => ref.invalidate(staffStatisticsProvider),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    StaffStatisticsModel? stats,
  ) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final decimal = NumberFormat(
      '#,##0.#',
      Localizations.localeOf(context).toLanguageTag(),
    );
    String count(int? v) => v == null ? '—' : formatCount(context, v);

    final perStaff = stats?.processingPerActiveStaff;
    final avgMinutes = stats?.avgResolutionMinutes;

    return KpiGrid(
      compact: compact,
      cards: [
        KpiCard(
          compact: compact,
          icon: Icons.badge_outlined,
          iconColor: theme.colorScheme.primary,
          label: l10n.totalStaff,
          value: count(stats?.totalStaff),
          footnote: stats == null
              ? null
              : KpiFootnote(
                  l10n.staffActiveBlocked(stats.activeStaff, stats.blockedStaff),
                ),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.pending_actions_outlined,
          iconColor: semantic.info,
          label: l10n.reportsInProgress,
          value: count(stats?.processingReports),
          footnote: perStaff == null
              ? null
              : KpiFootnote(l10n.avgPerActiveStaff(decimal.format(perStaff))),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.task_alt,
          iconColor: semantic.success,
          label: l10n.resolvedInMonth,
          value: count(stats?.resolved),
          footnote: KpiFootnote.change(
            context,
            current: stats?.resolved,
            previous: stats?.resolvedPrevious,
            tone: ChangeTone.higherIsBetter,
          ),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.timer_outlined,
          iconColor: theme.colorScheme.secondary,
          label: l10n.avgResolutionTimeInMonth,
          value: avgMinutes == null
              ? '—'
              : formatResolutionDuration(context, avgMinutes),
          footnote: stats == null
              ? null
              : avgMinutes == null
              ? KpiFootnote(l10n.notEnoughData)
              : KpiFootnote.change(
                  context,
                  current: avgMinutes,
                  previous: stats.avgResolutionMinutesPrevious,
                  // Xử lý nhanh hơn (thời gian giảm) mới là tốt
                  tone: ChangeTone.lowerIsBetter,
                ),
        ),
      ],
    );
  }
}

/// Luồng xử lý: số báo cáo được phân công (vào) và đã xử lý (ra) theo thời gian.
class StaffFlowChart extends ConsumerStatefulWidget {
  final double chartHeight;
  const StaffFlowChart({super.key, this.chartHeight = 220});

  @override
  ConsumerState<StaffFlowChart> createState() => _StaffFlowChartState();
}

class _StaffFlowChartState extends ConsumerState<StaffFlowChart> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trendAsync = ref.watch(staffTrendProvider(_period));

    return ChartCard(
      title: l10n.processingFlow,
      trailing: PeriodDropdown(
        value: _period,
        onChanged: (p) => setState(() => _period = p),
      ),
      child: SizedBox(
        height: widget.chartHeight,
        child: trendAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return ChartPlaceholder.empty(message: l10n.noData);
            }
            final assigned = TrendSeries(
              label: l10n.assignedSeries,
              // Đường phụ trợ dùng màu trung tính để "Đã xử lý" nổi bật
              color: theme.colorScheme.onSurfaceVariant,
              values: [for (final item in items) item.assigned],
            );
            final resolved = TrendSeries(
              label: l10n.resolvedSeries,
              color: theme.colorScheme.primary,
              values: [for (final item in items) item.resolved],
              showArea: true,
            );
            return TrendLineChart(
              period: _period,
              dates: [for (final item in items) item.date],
              series: [assigned, resolved],
              tooltipValue: (series, value) => identical(series, assigned)
                  ? l10n.assignedReportsCount(value)
                  : l10n.resolvedReportsCount(value),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ChartPlaceholder.error(
            onRetry: () => ref.invalidate(staffTrendProvider(_period)),
          ),
        ),
      ),
    );
  }
}

/// Khối lượng công việc: nhân viên đang xử lý nhiều báo cáo nhất. Bấm để xem chi tiết.
class StaffWorkloadChart extends ConsumerWidget {
  const StaffWorkloadChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statsAsync = ref.watch(staffStatisticsProvider);
    final avgText = statsAsync.maybeWhen(
      data: (stats) => NumberFormat('#,##0.#',
              Localizations.localeOf(context).toLanguageTag())
          .format(stats.teamAvgWeightedLoad),
      orElse: () => null,
    );

    return ChartCard(
      title: l10n.workloadChart,
      subtitle: avgText == null
          ? l10n.workloadSubtitle
          : '${l10n.workloadSubtitle} • ${l10n.teamAvgWeightedLoadLabel(avgText)}',
      child: statsAsync.when(
        data: (stats) {
          if (stats.workload.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: ChartPlaceholder.empty(message: l10n.noWorkloadData),
            );
          }
          final staffById = {
            for (final item in stats.workload) item.staff.id: item.staff,
          };
          return RankedBarList(
            items: [
              for (final item in stats.workload)
                RankedBarItem(
                  id: item.staff.id,
                  name: item.staff.fullName,
                  avatarUrl: item.staff.avatarUrl,
                  value: item.weightedLoad > 0
                      ? item.weightedLoad
                      : item.staff.processingCount,
                  subtitle: [
                    l10n.weightedLoadValue(
                      item.weightedLoad,
                      item.staff.processingCount,
                    ),
                    l10n.resolvedMonthCount(item.resolvedCount),
                    if (item.isOverloaded) l10n.staffOverloadedBadge,
                  ].join(' • '),
                ),
            ],
            onTap: (item) {
              final staff = staffById[item.id];
              if (staff != null) {
                showStaffDetailSheet(context, l10n, theme, staff, ref);
              }
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ChartPlaceholder.error(
            onRetry: () => ref.invalidate(staffStatisticsProvider),
          ),
        ),
      ),
    );
  }
}

/// Thống kê hiệu suất xử lý phản ánh của nhân viên dựa vào tình trạng trễ deadline.
class StaffDeadlinePerformanceCard extends ConsumerWidget {
  final bool compact;
  const StaffDeadlinePerformanceCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final statsAsync = ref.watch(staffStatisticsProvider);

    return ChartCard(
      title: l10n.staffDeadlinePerformanceTitle,
      subtitle: l10n.staffDeadlinePerformanceSubtitle,
      child: statsAsync.when(
        data: (stats) => _buildBody(context, ref, l10n, theme, semantic, stats),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ChartPlaceholder.error(
            onRetry: () => ref.invalidate(staffStatisticsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    AppSemanticColors semantic,
    StaffStatisticsModel stats,
  ) {
    final cs = theme.colorScheme;
    final missed = stats.anyStaffMissedDeadline;
    final statusColor = missed ? cs.error : semantic.success;
    final rateText = stats.onTimeRate == null
        ? null
        : l10n.onTimeRateLabel(
            NumberFormat('#,##0.#', Localizations.localeOf(context).toLanguageTag())
                .format(stats.onTimeRate!),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(
                missed ? Icons.warning_amber_rounded : Icons.verified_outlined,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missed
                      ? l10n.staffMissedDeadlineSummary(
                          stats.overdueReports,
                          stats.completedLate,
                        )
                      : l10n.noStaffMissedDeadline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (rateText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rateText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeadlineMetricTile(
                label: l10n.overdueActiveLabel,
                value: formatCount(context, stats.overdueReports),
                accent: stats.overdueReports > 0 ? cs.error : cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DeadlineMetricTile(
                label: l10n.completedLateLabel,
                value: formatCount(context, stats.completedLate),
                accent: stats.completedLate > 0 ? semantic.warning : cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DeadlineMetricTile(
                label: l10n.completedOnTimeLabel,
                value: formatCount(context, stats.completedOnTime),
                accent: semantic.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (stats.deadlinePerformance.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.noDeadlineRecordsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else ...[
          for (final item in stats.deadlinePerformance.take(compact ? 5 : 8))
            _DeadlineStaffRow(
              item: item,
              semantic: semantic,
              onTap: () => showStaffDetailSheet(
                context,
                l10n,
                theme,
                item.staff,
                ref,
              ),
            ),
        ],
      ],
    );
  }
}

class _DeadlineMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DeadlineMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineStaffRow extends StatelessWidget {
  final StaffDeadlinePerformanceItem item;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _DeadlineStaffRow({
    required this.item,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badgeColor = item.hasMissedDeadline ? cs.error : semantic.success;
    final name = item.staff.fullName.isNotEmpty
        ? item.staff.fullName
        : item.staff.email;
    final avatar = item.staff.avatarUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              foregroundImage: (avatar != null && avatar.isNotEmpty)
                  ? NetworkImage(avatar)
                  : null,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.staffDeadlineStatsBreakdown(
                      item.overdueCount,
                      item.completedLateCount,
                      item.completedOnTimeCount,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.efficiencyRate == null
                            ? l10n.staffEfficiencyNoData
                            : l10n.staffEfficiencyLabel(
                                NumberFormat(
                                  '#,##0.#',
                                  Localizations.localeOf(context).toLanguageTag(),
                                ).format(item.efficiencyRate!),
                              ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: item.efficiencyRate == null
                              ? cs.onSurfaceVariant
                              : badgeColor,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (item.bottleneckCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            l10n.staffBottleneckCountBadge(
                                item.bottleneckCount),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.error,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (item.weightedLoad > 0 ||
                      item.staff.processingCount > 0 ||
                      item.isOverloaded) ...[
                    const SizedBox(height: 4),
                    StaffWorkloadBadge(
                      weightedLoad: item.weightedLoad,
                      processingCount: item.staff.processingCount,
                      isOverloaded: item.isOverloaded,
                      assignmentHint: item.staff.assignmentHint,
                      severityBreakdown: item.staff.severityBreakdown,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.hasMissedDeadline
                    ? l10n.missedDeadlineBadge
                    : l10n.excellentBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
