import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/my_reports_provider.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/reports/widgets/my_report_card.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/routes/router_path.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(myReportsProvider);
    final notifier = ref.read(myReportsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myReports),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => notifier.refresh(),
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => notifier.refresh(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(context, state),
                      const SizedBox(height: 16),
                      _buildFilterChips(context, state, notifier),
                      const SizedBox(height: 16),
                      ..._buildGroupedList(context, state, ref),
                    ],
                  ),
                ),
    );
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
              '${state.totalCount}',
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
                    state.processingCount,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    l10n.reportStatusProcessed,
                    state.processedCount,
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

  Widget _buildFilterChips(BuildContext context, MyReportsState state, MyReportsNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      {'label': l10n.viewAll, 'value': null},
      {'label': l10n.reportStatusPending, 'value': 'pending'},
      {'label': l10n.reportStatusProcessing, 'value': 'processing'},
      {'label': l10n.reportStatusProcessed, 'value': 'processed'},
      {'label': l10n.rehandling, 'value': 'rehandling'},
      {'label': l10n.reportStatusRejected, 'value': 'rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = state.currentFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String),
              selected: isSelected,
              onSelected: (_) => notifier.setFilter(f['value']),
              showCheckmark: false,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context, MyReportsState state, WidgetRef ref) {
    final groups = state.groupedReports;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (state.displayReports.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              l10n.noReportsYet,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
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
