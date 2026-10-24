import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_dashboard_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart';

class MobileStaffView extends ConsumerStatefulWidget {
  const MobileStaffView({super.key});

  @override
  ConsumerState<MobileStaffView> createState() => _MobileStaffViewState();
}

class _MobileStaffViewState extends ConsumerState<MobileStaffView> {
  final _searchController = TextEditingController();
  bool _showStatistics = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(staffStatisticsProvider);
    ref.invalidate(staffTrendProvider);
    await ref.read(staffListProvider.notifier).refresh();
  }

  Widget _buildStatisticsToggle(ThemeData theme, AppLocalizations l10n) {
    return InkWell(
      onTap: () => setState(() => _showStatistics = !_showStatistics),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.statistics,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _showStatistics ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final staffAsync = ref.watch(staffListProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.manageStaffs,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () =>
                            showStaffFormDialog(context, l10n, theme, ref),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // KPI 2x2
                  const StaffKpiGrid(compact: true),
                  const SizedBox(height: 8),

                  // Thống kê chi tiết — thu gọn mặc định để danh sách lên sớm
                  _buildStatisticsToggle(theme, l10n),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _showStatistics
                        ? const Column(
                            children: [
                              StaffFlowChart(chartHeight: 200),
                              SizedBox(height: 12),
                              StaffWorkloadChart(),
                              SizedBox(height: 4),
                            ],
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 12),

                  // Search bar + filter icon
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => ref
                              .read(staffListProvider.notifier)
                              .setSearch(v),
                          decoration: InputDecoration(
                            hintText: l10n.searchPlaceholder,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: theme.dividerColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () =>
                            _showFilterBottomSheet(context, theme, l10n),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Staff cards list
          staffAsync.when(
            data: (data) {
              if (data.staffs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(l10n.noStaffFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: data.staffs.length + 1, // +1 for pagination
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == data.staffs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: StaffPaginationControls(data: data),
                      );
                    }
                    final staff = data.staffs[index];
                    return StaffCard(
                      staff: staff,
                      onTap: () =>
                          showStaffDetailSheet(context, l10n, theme, staff, ref),
                    );
                  },
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: 4,
                itemBuilder: (_, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(error.toString()),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(staffListProvider.notifier).refresh(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final successColor = AppSemanticColors.of(context).success;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filterByStatus,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.all),
                leading: const Icon(Icons.people_outline),
                onTap: () {
                  ref.read(staffListProvider.notifier).setStatusFilter('all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.activeStatus),
                leading: Icon(Icons.check_circle_outline,
                    color: successColor),
                onTap: () {
                  ref
                      .read(staffListProvider.notifier)
                      .setStatusFilter('active');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.blockedStatus),
                leading:
                    Icon(Icons.lock_outline, color: theme.colorScheme.error),
                onTap: () {
                  ref
                      .read(staffListProvider.notifier)
                      .setStatusFilter('blocked');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
