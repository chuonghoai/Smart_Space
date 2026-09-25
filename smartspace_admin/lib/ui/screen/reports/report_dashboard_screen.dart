import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_dashboard_providers.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_filter_bar.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_kanban_board.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_severity_chart.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_stat_cards.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_table_view.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_trend_chart.dart';

class ReportDashboardScreen extends ConsumerStatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  ConsumerState<ReportDashboardScreen> createState() =>
      _ReportDashboardScreenState();
}

class _ReportDashboardScreenState
    extends ConsumerState<ReportDashboardScreen> {
  final _searchController = TextEditingController();
  int _viewMode = 0; // 0 = Table, 1 = Kanban (Web only)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppLayout(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reportStatisticsProvider.notifier).refresh();
          ref.invalidate(reportTrendProvider);
          ref.invalidate(reportListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page title ───────────────────────────────────────────────
              Text(
                l10n.reportDashboard,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── 1. Summary Cards ─────────────────────────────────────────
              const ReportStatCards(),
              const SizedBox(height: 24),

              // ── 2. Charts — responsive ───────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 700) {
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
                  return const Column(
                    children: [
                      ReportTrendChart(),
                      SizedBox(height: 16),
                      ReportSeverityChart(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── 3. Report List (inline) ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.reportList,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // View toggle — Web only
                  if (kIsWeb)
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.table_rows_outlined, size: 16),
                          label: Text(l10n.tableView),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon:
                              const Icon(Icons.view_kanban_outlined, size: 16),
                          label: Text(l10n.kanbanView),
                        ),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (s) =>
                          setState(() => _viewMode = s.first),
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter bar
              const ReportFilterBar(),
              const SizedBox(height: 10),

              // Search
              TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(reportListProvider.notifier).setSearch(v),
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã, tiêu đề, email người gửi...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(reportListProvider.notifier)
                                .setSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),

              // Table or Kanban
              if (_viewMode == 0 || !kIsWeb)
                const ReportTableView()
              else
                const ReportKanbanBoard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
