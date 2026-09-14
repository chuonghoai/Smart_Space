import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_list_response.dart';
import 'package:smartspace_admin/features/staff/models/staff_summary_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';

class WebStaffView extends ConsumerStatefulWidget {
  const WebStaffView({super.key});

  @override
  ConsumerState<WebStaffView> createState() => _WebStaffViewState();
}

class _WebStaffViewState extends ConsumerState<WebStaffView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final staffAsync = ref.watch(staffListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(l10n, theme, staffAsync),
          const SizedBox(height: 20),

          // Summary Cards
          staffAsync.when(
            data: (data) => _buildWebSummaryCards(theme, data.summary, l10n),
            loading: () => const SizedBox(height: 90),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Search + Filter
          _buildWebSearchBar(l10n, theme),
          const SizedBox(height: 16),

          // Data Table
          staffAsync.when(
            data: (data) => _buildWebDataTable(l10n, theme, data),
            loading: () => _buildShimmer(theme, 6),
            error: (error, _) => _buildError(theme, l10n, error),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme,
      AsyncValue<StaffListResponse> staffAsync) {
    final total = staffAsync.valueOrNull?.summary.total ?? 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l10n.manageStaffs} · $total',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        FilledButton.icon(
          onPressed: () => showAddStaffDialog(context, l10n, theme),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addStaff),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSummaryCards(ThemeData theme, StaffSummaryModel summary, AppLocalizations l10n) {
    final successColor = theme.brightness == Brightness.light ? const Color(0xFF2E7D32) : const Color(0xFF66BB6A);
    final warningColor = theme.brightness == Brightness.light ? const Color(0xFFF9A825) : const Color(0xFFFFCA28);
    
    return Row(
      children: [
        Expanded(
          child: _WebKpiCard(
            icon: Icons.people_outline,
            iconColor: theme.colorScheme.primary,
            value: '${summary.total}',
            label: l10n.totalStaff,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _WebKpiCard(
            icon: Icons.check_circle_outline,
            iconColor: successColor,
            value: '${summary.active}',
            label: l10n.activeStatus,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _WebKpiCard(
            icon: Icons.lock_outline,
            iconColor: theme.colorScheme.error,
            value: '${summary.blocked}',
            label: l10n.blockedStatus,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _WebKpiCard(
            icon: Icons.assignment_outlined,
            iconColor: warningColor,
            value: '${summary.totalProcessing}',
            label: l10n.processingStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildWebSearchBar(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(staffListProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'all',
              items: [
                DropdownMenuItem(value: 'all', child: Text(l10n.all)),
                DropdownMenuItem(
                    value: 'active', child: Text(l10n.activeStatus)),
                DropdownMenuItem(
                    value: 'blocked', child: Text(l10n.blockedStatus)),
              ],
              onChanged: (v) =>
                  ref.read(staffListProvider.notifier).setStatusFilter(v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebDataTable(
      AppLocalizations l10n, ThemeData theme, StaffListResponse data) {
    if (data.staffs.isEmpty) {
      return _buildEmptyState(theme, l10n, data.totalElements == 0);
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerLow),
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(l10n.staffMember)),
              DataColumn(label: Text(l10n.email)),
              DataColumn(label: Text(l10n.phoneNumber)),
              DataColumn(label: Text(l10n.processingStatus)),
              DataColumn(label: Text(l10n.statusTitle)),
              const DataColumn(label: Text('')),
            ],
            rows: data.staffs.map((staff) {
              return DataRow(
                color: staff.isBlocked
                    ? WidgetStateProperty.all(
                        theme.colorScheme.onSurface.withValues(alpha: 0.04))
                    : null,
                cells: [
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StaffAvatar(staff: staff, radius: 16),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          staff.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: staff.isBlocked
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  )),
                  DataCell(Text(
                    staff.email,
                    style: TextStyle(
                      color: staff.isBlocked
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  )),
                  DataCell(Text(
                    staff.phoneNumber ?? '—',
                    style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  )),
                  DataCell(Text(
                    '${staff.processingCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: staff.processingCount > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                    ),
                  )),
                  DataCell(StaffStatusChip(isActive: staff.isActive)),
                  DataCell(
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (v) {
                        if (v == 'detail') {
                          showStaffDetailSheet(
                              context, l10n, theme, staff);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'detail', child: Text(l10n.viewDetails)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        StaffPaginationControls(data: data),
      ],
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, AppLocalizations l10n, bool isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(isEmpty ? Icons.people_outline : Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              isEmpty
                  ? l10n.noStaffInSystem
                  : l10n.noStaffFound,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, int count) {
    return Column(
      children: List.generate(
          count,
          (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
    );
  }

  Widget _buildError(ThemeData theme, AppLocalizations l10n, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(error.toString(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(staffListProvider.notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard-style KPI card — full-width, large value, label + icon
class _WebKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _WebKpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
