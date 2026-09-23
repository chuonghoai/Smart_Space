import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_severity_chart.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_stat_cards.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_trend_chart.dart';

class ReportDashboardScreen extends ConsumerWidget {
  const ReportDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppLayout(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reportStatisticsProvider.notifier).refresh();
          ref.invalidate(reportTrendProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Text(
                l10n.reportDashboard,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 1. Summary Cards
              const ReportStatCards(),
              const SizedBox(height: 24),

              // 2. Charts — responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 700) {
                    // Web: 2 cột
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: ReportTrendChart()),
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 300,
                          child: ReportSeverityChart(),
                        ),
                      ],
                    );
                  }
                  // Mobile: xếp dọc
                  return const Column(
                    children: [
                      ReportTrendChart(),
                      SizedBox(height: 16),
                      ReportSeverityChart(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
