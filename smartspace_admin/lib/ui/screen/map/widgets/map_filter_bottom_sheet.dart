import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/report_timeframe.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Modal bottom sheet lọc phản ánh trên bản đồ Admin.
/// Hiển thị dạng slide-up từ dưới lên.
class MapFilterBottomSheet extends ConsumerWidget {
  const MapFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MapFilterBottomSheet(),
    );
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(mapFilterProvider.notifier).state = const ReportFilter(size: 500);
    ref.read(adminReportDensityProvider.notifier).setTimeframe(ReportTimeframe.all);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filter = ref.watch(mapFilterProvider);
    final staffsAsync = ref.watch(mapStaffListProvider);

    int activeCount = 0;
    if (filter.status != null && filter.status!.isNotEmpty) activeCount++;
    if (filter.severity != null && filter.severity!.isNotEmpty) activeCount++;
    if (filter.from != null || filter.to != null) activeCount++;
    if (filter.assigneeId != null && filter.assigneeId!.isNotEmpty) activeCount++;
    if (filter.timeframe != null &&
        filter.timeframe!.isNotEmpty &&
        filter.timeframe != 'all') {
      activeCount++;
    }

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      elevation: 10,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      l10n.mapFilterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable filter content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Text(
                        l10n.mapFilterStatus,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            context: context,
                            label: l10n.mapFilterAll,
                            selected:
                                filter.status == null || filter.status!.isEmpty,
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(clearStatus: true),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: l10n.reportStatusPending,
                            selected: filter.status == 'pending',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(status: 'pending'),
                            selectedColor: const Color(0xFFEF5350)
                                .withValues(alpha: 0.2),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: l10n.reportStatusProcessing,
                            selected: filter.status == 'processing',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(status: 'processing'),
                            selectedColor: const Color(0xFFFFCA28)
                                .withValues(alpha: 0.2),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: l10n.reportStatusProcessed,
                            selected: filter.status == 'processed',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(status: 'processed'),
                            selectedColor: const Color(0xFF66BB6A)
                                .withValues(alpha: 0.2),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: l10n.reportStatusRejected,
                            selected: filter.status == 'rejected',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(status: 'rejected'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Severity
                      Text(
                        l10n.mapFilterSeverity,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            context: context,
                            label: l10n.mapFilterAll,
                            selected: filter.severity == null ||
                                filter.severity!.isEmpty,
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(clearSeverity: true),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: 'Low',
                            selected: filter.severity == 'low',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(severity: 'low'),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: 'Medium',
                            selected: filter.severity == 'medium',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(severity: 'medium'),
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: 'High',
                            selected: filter.severity == 'high',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(severity: 'high'),
                            selectedColor: cs.errorContainer,
                          ),
                          _buildChoiceChip(
                            context: context,
                            label: 'Critical',
                            selected: filter.severity == 'critical',
                            onSelected: (_) => ref
                                .read(mapFilterProvider.notifier)
                                .state = filter.copyWith(severity: 'critical'),
                            selectedColor: cs.errorContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Timeframe
                      Text(
                        l10n.filterTimeframe,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ReportTimeframe.values.map((tf) {
                          final isSelected =
                              (filter.timeframe ?? 'all') == tf.code;
                          return _buildChoiceChip(
                            context: context,
                            label: tf.localizedLabel(context),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(mapFilterProvider.notifier).state =
                                  filter.copyWith(timeframe: tf.code);
                              ref
                                  .read(adminReportDensityProvider.notifier)
                                  .setTimeframe(tf);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Date Range
                      Text(
                        l10n.mapFilterDateRange,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            initialDateRange:
                                filter.from != null && filter.to != null
                                    ? DateTimeRange(
                                        start: filter.from!, end: filter.to!)
                                    : null,
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            ref.read(mapFilterProvider.notifier).state =
                                filter.copyWith(
                              from: picked.start,
                              to: picked.end,
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          filter.from != null && filter.to != null
                              ? '${DateFormat('dd/MM/yyyy').format(filter.from!)} - ${DateFormat('dd/MM/yyyy').format(filter.to!)}'
                              : l10n.mapFilterAll,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Assignee
                      Text(
                        l10n.mapFilterAssignee,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: filter.assigneeId,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.mapFilterAll),
                          ),
                          ...staffsAsync.maybeWhen(
                            data: (staffs) => staffs.map((staff) {
                              return DropdownMenuItem(
                                value: staff.id,
                                child: Text(staff.fullName),
                              );
                            }).toList(),
                            orElse: () => [],
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            ref.read(mapFilterProvider.notifier).state =
                                filter.copyWith(clearAssignee: true);
                          } else {
                            ref.read(mapFilterProvider.notifier).state =
                                filter.copyWith(assigneeId: val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action buttons: Clear & Apply
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _clearFilters(ref),
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: Text(l10n.mapFilterClear),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(l10n.mapFilterApply),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Color? selectedColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? cs.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? cs.onPrimaryContainer : cs.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

