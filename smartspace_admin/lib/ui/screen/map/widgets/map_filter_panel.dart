import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class MapFilterPanel extends ConsumerStatefulWidget {
  const MapFilterPanel({super.key});

  @override
  ConsumerState<MapFilterPanel> createState() => _MapFilterPanelState();
}

class _MapFilterPanelState extends ConsumerState<MapFilterPanel> {
  bool _isExpanded = false;

  void _clearFilters() {
    ref.read(mapFilterProvider.notifier).state = const ReportFilter(size: 500);
  }

  @override
  Widget build(BuildContext context) {
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.mapFilterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    const Spacer(),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Status
                    Text(l10n.mapFilterStatus, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChoiceChip(
                          label: l10n.mapFilterAll,
                          selected: filter.status == null || filter.status!.isEmpty,
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(clearStatus: true),
                        ),
                        _buildChoiceChip(
                          label: l10n.reportStatusPending,
                          selected: filter.status == 'pending',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(status: 'pending'),
                          selectedColor: const Color(0xFFEF5350).withOpacity(0.2),
                        ),
                        _buildChoiceChip(
                          label: l10n.reportStatusProcessing,
                          selected: filter.status == 'processing',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(status: 'processing'),
                          selectedColor: const Color(0xFFFFCA28).withOpacity(0.2),
                        ),
                        _buildChoiceChip(
                          label: l10n.reportStatusProcessed,
                          selected: filter.status == 'processed',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(status: 'processed'),
                          selectedColor: const Color(0xFF66BB6A).withOpacity(0.2),
                        ),
                        _buildChoiceChip(
                          label: l10n.reportStatusRejected,
                          selected: filter.status == 'rejected',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(status: 'rejected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Severity
                    Text(l10n.mapFilterSeverity, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChoiceChip(
                          label: l10n.mapFilterAll,
                          selected: filter.severity == null || filter.severity!.isEmpty,
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(clearSeverity: true),
                        ),
                        _buildChoiceChip(
                          label: 'Low',
                          selected: filter.severity == 'low',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(severity: 'low'),
                        ),
                        _buildChoiceChip(
                          label: 'Medium',
                          selected: filter.severity == 'medium',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(severity: 'medium'),
                        ),
                        _buildChoiceChip(
                          label: 'High',
                          selected: filter.severity == 'high',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(severity: 'high'),
                          selectedColor: cs.errorContainer,
                        ),
                        _buildChoiceChip(
                          label: 'Critical',
                          selected: filter.severity == 'critical',
                          onSelected: (_) => ref.read(mapFilterProvider.notifier).state = filter.copyWith(severity: 'critical'),
                          selectedColor: cs.errorContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date Range
                    Text(l10n.mapFilterDateRange, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: filter.from != null && filter.to != null
                              ? DateTimeRange(start: filter.from!, end: filter.to!)
                              : null,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          ref.read(mapFilterProvider.notifier).state = filter.copyWith(
                            from: picked.start,
                            to: picked.end,
                          );
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        filter.from != null && filter.to != null
                            ? '${DateFormat('dd/MM/yyyy').format(filter.from!)} - ${DateFormat('dd/MM/yyyy').format(filter.to!)}'
                            : l10n.mapFilterAll,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Assignee
                    Text(l10n.mapFilterAssignee, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: filter.assigneeId,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
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
                          ref.read(mapFilterProvider.notifier).state = filter.copyWith(clearAssignee: true);
                        } else {
                          ref.read(mapFilterProvider.notifier).state = filter.copyWith(assigneeId: val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: activeCount > 0 ? _clearFilters : null,
                          child: Text(l10n.mapFilterClear),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            setState(() => _isExpanded = false);
                          },
                          child: Text(l10n.mapFilterApply),
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required void Function(bool) onSelected,
    Color? selectedColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.all(4),
    );
  }
}
