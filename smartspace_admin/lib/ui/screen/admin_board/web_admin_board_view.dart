import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/admin_accounts/application/admin_account_providers.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/admin_board_shared_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart'
    show StaffStatusChip;

class WebAdminBoardView extends ConsumerStatefulWidget {
  const WebAdminBoardView({super.key});

  @override
  ConsumerState<WebAdminBoardView> createState() => _WebAdminBoardViewState();
}

class _WebAdminBoardViewState extends ConsumerState<WebAdminBoardView> {
  // Đủ rộng để đặt panel chi tiết cạnh bảng
  static const double _sidePanelBreakpoint = 1100;
  static const double _sidePanelWidth = 360;

  final _searchController = TextEditingController();
  AdminAccountModel? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Bản mới nhất của admin đang chọn (sau khi khóa/mở khóa danh sách được tải lại).
  AdminAccountModel? _resolveSelected(AdminAccountListState? data) {
    final selected = _selected;
    if (selected == null || data == null) return selected;
    for (final admin in data.admins) {
      if (admin.id == selected.id) return admin;
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(adminAccountListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n, theme),
          const SizedBox(height: 20),
          _buildSearchBar(l10n, theme),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _sidePanelBreakpoint;
              final table = listAsync.when(
                data: (data) => _buildTable(l10n, theme, data, wide),
                loading: () => _buildShimmer(theme),
                error: (error, _) => _buildError(theme, l10n, error),
              );
              if (!wide) return table;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: table),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: _sidePanelWidth,
                    child: _buildSidePanel(
                      l10n,
                      theme,
                      _resolveSelected(listAsync.valueOrNull),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminBoard,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const AdminSummaryBadges(),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => showAdminFormDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addAdmin),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, ThemeData theme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: theme.dividerColor),
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(adminAccountListProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search),
              border: border,
              enabledBorder: border,
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
              value: ref.watch(adminStatusFilterProvider),
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
                  ref.read(adminAccountListProvider.notifier).setStatusFilter(v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(
    AppLocalizations l10n,
    ThemeData theme,
    AdminAccountListState data,
    bool wide,
  ) {
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.7);
    final selectedId = _selected?.id;

    // Empty state giữ khung bảng
    final Widget body = data.admins.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noAdminFound,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        : LayoutBuilder(
            // Bảng giãn hết bề ngang; hẹp hơn nội dung thì cuộn ngang thay vì tràn
            builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  cs.surfaceContainerLow,
                ),
                headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text(l10n.admins)),
                  DataColumn(label: Text(l10n.email)),
                  DataColumn(label: Text(l10n.phoneNumber)),
                  DataColumn(label: Text(l10n.createdAt)),
                  DataColumn(label: Text(l10n.statusTitle)),
                  const DataColumn(label: Text('')),
                ],
                rows: data.admins.map((admin) {
                  final dimmed = !admin.isActive;
                  final reason = adminToggleBlockedReason(l10n, data, admin);
                  return DataRow(
                    selected: wide && admin.id == selectedId,
                    color: dimmed
                        ? WidgetStateProperty.all(
                            cs.onSurface.withValues(alpha: 0.04),
                          )
                        : null,
                    onSelectChanged: (_) => _openDetail(admin, wide),
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdminAvatar(admin: admin, radius: 16),
                            const SizedBox(width: 10),
                            Flexible(
                              child: AdminNameLine(
                                admin: admin,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: dimmed
                                      ? cs.onSurface.withValues(alpha: 0.5)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(admin.email, style: TextStyle(color: muted))),
                      DataCell(
                        Text(admin.phoneNumber ?? '—', style: TextStyle(color: muted)),
                      ),
                      DataCell(
                        Text(
                          formatAdminDate(admin.createdAt),
                          style: TextStyle(color: muted),
                        ),
                      ),
                      DataCell(StaffStatusChip(isActive: admin.isActive)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: l10n.viewDetails,
                              child: IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                onPressed: () => _openDetail(admin, wide),
                              ),
                            ),
                            Tooltip(
                              // Nút bị khóa vẫn giải thích lý do khi rê chuột
                              message: reason ??
                                  (admin.isActive
                                      ? l10n.lockAccount
                                      : l10n.unlockAccount),
                              child: IconButton(
                                icon: Icon(
                                  admin.isActive
                                      ? Icons.lock_outline
                                      : Icons.lock_open,
                                  size: 20,
                                  color: reason != null
                                      ? null
                                      : (admin.isActive ? cs.error : cs.primary),
                                ),
                                onPressed: reason != null
                                    ? null
                                    : () => confirmToggleAdminStatus(
                                          context,
                                          ref,
                                          admin,
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
            ),
          );

    return Column(
      children: [
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: body,
        ),
        const SizedBox(height: 16),
        _AdminPaginationControls(
          currentPage: data.currentPage,
          totalPages: data.totalPages,
          onPageSelected: (page) =>
              ref.read(adminAccountListProvider.notifier).goToPage(page),
        ),
      ],
    );
  }

  void _openDetail(AdminAccountModel admin, bool wide) {
    if (wide) {
      setState(() => _selected = admin);
    } else {
      showAdminDetailDialog(context, admin);
    }
  }

  Widget _buildSidePanel(
    AppLocalizations l10n,
    ThemeData theme,
    AdminAccountModel? selected,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: selected == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l10n.selectAdminHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : AdminDetailPanel(key: ValueKey(selected.id), admin: selected),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return Column(
      children: List.generate(
        6,
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
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.read(adminAccountListProvider.notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phân trang Previous / 1 2 3 / Next.
class _AdminPaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  const _AdminPaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageSelected(currentPage - 1) : null,
        ),
        const SizedBox(width: 8),
        for (var page = 1; page <= totalPages; page++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: page == currentPage ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: page == currentPage ? null : () => onPageSelected(page),
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color: page == currentPage ? cs.onPrimary : cs.onSurface,
                        fontWeight: page == currentPage
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () => onPageSelected(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
