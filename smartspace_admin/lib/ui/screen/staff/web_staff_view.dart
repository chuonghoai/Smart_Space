import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_list_response.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_dashboard_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';
import 'package:smartspace_admin/ui/shared/dashboard/kpi_card.dart';

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

          // KPI
          const StaffKpiGrid(),
          const SizedBox(height: 20),

          // Charts — 2/3 luồng xử lý + 1/3 khối lượng công việc, xếp dọc khi hẹp
          LayoutBuilder(
            builder: (context, constraints) {
              const flow = StaffFlowChart();
              const workload = StaffWorkloadChart();
              if (constraints.maxWidth < 900) {
                return const Column(
                  children: [flow, SizedBox(height: 16), workload],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: flow),
                  SizedBox(width: 16),
                  Expanded(child: workload),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

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

  Widget _buildHeader(
    AppLocalizations l10n,
    ThemeData theme,
    AsyncValue<StaffListResponse> staffAsync,
  ) {
    final total =
        ref.watch(
          staffStatisticsProvider.select((s) => s.valueOrNull?.totalStaff),
        ) ??
        staffAsync.valueOrNull?.summary.total;
    return Row(
      children: [
        Expanded(
          child: Text(
            total == null
                ? l10n.manageStaffs
                : '${l10n.manageStaffs} · ${formatCount(context, total)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => showStaffFormDialog(context, l10n, theme, ref),
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

  Widget _buildWebSearchBar(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => ref.read(staffListProvider.notifier).setSearch(v),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                  value: 'active',
                  child: Text(l10n.activeStatus),
                ),
                DropdownMenuItem(
                  value: 'blocked',
                  child: Text(l10n.blockedStatus),
                ),
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
    AppLocalizations l10n,
    ThemeData theme,
    StaffListResponse data,
  ) {
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
              theme.colorScheme.surfaceContainerLow,
            ),
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
                        theme.colorScheme.onSurface.withValues(alpha: 0.04),
                      )
                    : null,
                cells: [
                  DataCell(
                    Row(
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
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      staff.email,
                      style: TextStyle(
                        color: staff.isBlocked
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      staff.phoneNumber ?? '—',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${staff.processingCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: staff.processingCount > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                  ),
                  DataCell(StaffStatusChip(isActive: staff.isActive)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: l10n.viewDetails,
                          child: IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => showStaffDetailSheet(
                              context,
                              l10n,
                              theme,
                              staff,
                              ref,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: l10n.editInfo,
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => showStaffFormDialog(
                              context,
                              l10n,
                              theme,
                              ref,
                              editingStaff: staff,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: staff.isActive
                              ? l10n.lockAccount
                              : l10n.unlockAccount,
                          child: IconButton(
                            icon: Icon(
                              staff.isActive
                                  ? Icons.lock_outline
                                  : Icons.lock_open,
                              size: 20,
                              color: staff.isActive
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                            onPressed: () => confirmToggleStaffStatus(
                              context,
                              l10n,
                              theme,
                              staff,
                              ref,
                            ),
                          ),
                        ),
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
    ThemeData theme,
    AppLocalizations l10n,
    bool isEmpty,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty ? l10n.noStaffInSystem : l10n.noStaffFound,
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
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
