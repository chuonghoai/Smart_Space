import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/dashboard/chart_card.dart';
import 'package:smartspace_admin/ui/shared/dashboard/ranked_bar_list.dart';
import 'package:smartspace_admin/ui/shared/dashboard/trend_line_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trendAsync = ref.watch(userTrendProvider(_period));

    return ChartCard(
      title: l10n.registrationTrend,
      trailing: PeriodDropdown(
        value: _period,
        onChanged: (p) => setState(() => _period = p),
      ),
      child: SizedBox(
        height: widget.chartHeight,
        child: trendAsync.when(
          data: (items) => items.isEmpty
              ? ChartPlaceholder.empty(message: l10n.noData)
              : TrendLineChart(
                  period: _period,
                  dates: [for (final item in items) item.date],
                  series: [
                    TrendSeries(
                      label: l10n.registrationTrend,
                      color: theme.colorScheme.primary,
                      values: [for (final item in items) item.count],
                      showArea: true,
                    ),
                  ],
                  tooltipValue: (_, value) => l10n.newUsersCount(value),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ChartPlaceholder.error(
            onRetry: () => ref.invalidate(userTrendProvider(_period)),
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
    final statsAsync = ref.watch(userStatisticsProvider);

    return ChartCard(
      title: l10n.topContributors,
      subtitle: l10n.anonymousReportsExcluded,
      child: statsAsync.when(
        data: (stats) => stats.topReporters.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ChartPlaceholder.empty(message: l10n.noData),
              )
            : RankedBarList(
                items: [
                  for (final r in stats.topReporters)
                    RankedBarItem(
                      id: r.userId,
                      name: r.fullName,
                      avatarUrl: r.avatarUrl,
                      value: r.reportCount,
                    ),
                ],
                onTap: (item) => onUserTap(item.id),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ChartPlaceholder.error(
            onRetry: () => ref.invalidate(userStatisticsProvider),
          ),
        ),
      ),
    );
  }
}
