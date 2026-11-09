import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/my_reports_provider.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/components/report_filters/report_date_range_filter_chip.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_bar.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_chip.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_options.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_sheet.dart';
import 'package:smartspace_client/ui/mobile/reports/widgets/my_report_card.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/routes/router_path.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Provider sống xuyên màn hình → khôi phục từ khoá đang áp dụng
    _searchController.text = ref.read(myReportsProvider).searchQuery;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      ref.read(myReportsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myReportsProvider);
    final notifier = ref.read(myReportsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myReports),
        centerTitle: true,
      ),
      body: !state.hasLoaded
          ? const Center(child: CircularProgressIndicator())
          // Phần đầu (tổng hợp, tìm kiếm, chip) luôn hiển thị để ô tìm kiếm không mất focus khi tải lại
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                // Lề ngang đặt trên từng khối để hàng chip lọc cuộn được tới mép màn hình
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _gutter),
                    child: _buildSummaryCard(context, state),
                  ),
                  const SizedBox(height: 16),
                  ReportFilterBar(
                    searchController: _searchController,
                    searchHint: l10n.searchReportsPlaceholder,
                    onSearchChanged: notifier.search,
                    isFiltering: state.isFiltering,
                    onClearFilters: notifier.clearFilters,
                    resultCount: state.isLoading ? null : state.totalElements,
                    horizontalPadding: _gutter,
                    chips: _buildFilterChips(context, state, notifier),
                  ),
                  const SizedBox(height: 12),
                  for (final widget in _buildListContent(context, state, notifier))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _gutter),
                      child: widget,
                    ),
                ],
              ),
            ),
    );
  }

  static const double _gutter = 16;

  /// Vùng danh sách: loading / lỗi / trống / danh sách nhóm theo thời gian + loader tải thêm.
  List<Widget> _buildListContent(BuildContext context, MyReportsState state, MyReportsNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (state.isLoading && state.reports.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null && state.reports.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: notifier.refresh,
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      ..._buildGroupedList(context, state),
      if (state.isLoadingMore)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }

  Widget _buildSummaryCard(BuildContext context, MyReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.totalReports,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.summary.total}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.reportStatusProcessing,
                    state.summary.processing,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.reportStatusProcessed,
                    state.summary.processed,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, int count, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Widget> _buildFilterChips(BuildContext context, MyReportsState state, MyReportsNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final statusOptions = ReportFilterOptions.myReportStatuses(l10n);
    final severityOptions = ReportFilterOptions.severities(l10n);

    return [
      ReportFilterChip(
        label: l10n.statusLabel,
        valueLabel: ReportFilterOptions.selectedLabel(statusOptions, state.statusFilter),
        active: state.statusFilter != null,
        onTap: () => showReportFilterSheet(
          context: context,
          title: l10n.statusLabel,
          options: statusOptions,
          selected: state.statusFilter,
          onSelected: notifier.setFilter,
        ),
      ),
      ReportFilterChip(
        label: l10n.severityLabel,
        valueLabel: ReportFilterOptions.selectedLabel(severityOptions, state.severityFilter),
        active: state.severityFilter != null,
        onTap: () => showReportFilterSheet(
          context: context,
          title: l10n.severityLabel,
          options: severityOptions,
          selected: state.severityFilter,
          onSelected: notifier.setSeverity,
        ),
      ),
      ReportDateRangeFilterChip(
        value: state.dateRangeFilter,
        onChanged: notifier.setDateRange,
      ),
    ];
  }

  List<Widget> _buildGroupedList(BuildContext context, MyReportsState state) {
    final groups = state.groupedReports;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (state.reports.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Text(
                state.isFiltering ? l10n.noMatchingReports : l10n.noReportsYet,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (state.isFiltering) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(myReportsProvider.notifier).clearFilters();
                  },
                  child: Text(l10n.clearFilters),
                ),
              ],
            ],
          ),
        )
      ];
    }

    final List<Widget> widgets = [];

    void addGroup(String title, List<ReportModel> items) {
      if (items.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
      widgets.addAll(
        items.map((report) => MyReportCard(
              report: report,
              onTap: () {
                final String path = RouterPath.reportDetail.replaceAll(':id', report.id);
                context.push(path);
              },
              onEdit: () => _handleEdit(context, ref, report),
              onCancel: () => _handleCancel(context, ref, report),
            )),
      );
    }

    addGroup(l10n.today, groups['today']!);
    addGroup(l10n.thisWeek, groups['thisWeek']!);
    addGroup(l10n.older, groups['older']!);

    return widgets;
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref, ReportModel report) async {
    final l10n = AppLocalizations.of(context)!;

    // Strict constraint: Only pending reports can be edited
    if (report.status != ReportStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editReportOnlyPending)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await reportService.getReportDetail(report.id);
    if (context.mounted) {
      Navigator.of(context).pop(); // pop loading
    }

    if (res.success && res.data != null && context.mounted) {
      final updated = await context.push<bool>(
        RouterPath.createReport,
        extra: res.data,
      );
      if (updated == true) {
        ref.read(myReportsProvider.notifier).refresh();
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : l10n.genericError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, ReportModel report) async {
    final l10n = AppLocalizations.of(context)!;

    // Strict constraint: Only pending reports can be cancelled
    if (report.status != ReportStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cancelReportOnlyPending)),
      );
      return;
    }

    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelReportConfirmTitle),
        content: Text(l10n.cancelReportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.closeButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.cancelReport),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final res = await reportService.cancelReport(report.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
      }

      if (res.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cancelReportSuccess),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(myReportsProvider.notifier).refresh();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : l10n.genericError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
