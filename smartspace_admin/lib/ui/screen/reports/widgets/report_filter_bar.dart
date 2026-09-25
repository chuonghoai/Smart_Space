import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(reportFilterProvider);
    final staffAsync = ref.watch(staffsProvider);

    final statusItems = {
      '': l10n.all,
      'pending': l10n.pendingStatus,
      'processing': l10n.processingStatus,
      'processed': l10n.resolvedReports,
      'rejected': l10n.rejectedReports,
    };
    final severityItems = {
      '': l10n.all,
      'low': l10n.severityLow,
      'medium': l10n.severityMedium,
      'high': l10n.severityHigh,
      'critical': l10n.severityCritical,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Status
        _DropdownChip(
          label: l10n.filterByStatus,
          value: filter.status ?? '',
          items: statusItems,
          onChanged: (v) => ref.read(reportFilterProvider.notifier).state =
              filter.copyWith(
                  status: v!.isEmpty ? null : v,
                  clearStatus: v.isEmpty,
                  page: 1),
          theme: theme,
        ),

        // Severity
        _DropdownChip(
          label: l10n.filterBySeverity,
          value: filter.severity ?? '',
          items: severityItems,
          onChanged: (v) => ref.read(reportFilterProvider.notifier).state =
              filter.copyWith(
                  severity: v!.isEmpty ? null : v,
                  clearSeverity: v.isEmpty,
                  page: 1),
          theme: theme,
        ),

        // Assignee
        staffAsync.when(
          data: (staffList) {
            final assigneeItems = <String, String>{'': l10n.all};
            for (final s in staffList) {
              assigneeItems[s.id] = s.fullName;
            }
            return _DropdownChip(
              label: l10n.filterByAssignee,
              value: filter.assigneeId ?? '',
              items: assigneeItems,
              onChanged: (v) =>
                  ref.read(reportFilterProvider.notifier).state = filter
                      .copyWith(
                          assigneeId: v!.isEmpty ? null : v,
                          clearAssignee: v.isEmpty,
                          page: 1),
              theme: theme,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Date range
        ActionChip(
          avatar: Icon(Icons.date_range_outlined,
              size: 16, color: theme.colorScheme.primary),
          label: Text(
            filter.from != null
                ? '${DateFormat('dd/MM').format(filter.from!)} – ${DateFormat('dd/MM').format(filter.to!)}'
                : l10n.selectDateRange,
            style: theme.textTheme.labelMedium,
          ),
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: theme,
                child: child!,
              ),
            );
            if (range != null) {
              ref.read(reportFilterProvider.notifier).state = filter.copyWith(
                from: range.start,
                to: range.end,
                page: 1,
              );
            }
          },
        ),

        // Clear filters
        if (filter.isActive)
          ActionChip(
            avatar: const Icon(Icons.close, size: 16),
            label: Text(l10n.clearFilters,
                style: theme.textTheme.labelMedium),
            onPressed: () =>
                ref.read(reportFilterProvider.notifier).state =
                    const ReportFilter(),
          ),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  final ThemeData theme;

  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: theme.textTheme.labelMedium,
              items: items.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
