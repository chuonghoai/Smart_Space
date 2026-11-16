import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/admin_accounts/application/admin_account_providers.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/admin_board_shared_widgets.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart'
    show StaffStatusChip;

class MobileAdminBoardView extends ConsumerStatefulWidget {
  const MobileAdminBoardView({super.key});

  @override
  ConsumerState<MobileAdminBoardView> createState() =>
      _MobileAdminBoardViewState();
}

class _MobileAdminBoardViewState extends ConsumerState<MobileAdminBoardView> {
  // Còn cách đáy < ngưỡng này (px) thì tải trang tiếp theo
  static const double _loadMoreThreshold = 400;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      ref.read(adminAccountListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(adminAccountListProvider);

    // Trang đầu chưa lấp đầy màn hình → không có scroll để kích hoạt load more
    ref.listen(adminAccountListProvider, (_, next) {
      if (next.hasValue && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(adminAccountListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.adminBoard,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: l10n.addAdmin,
                        onPressed: () => showAdminFormDialog(context),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AdminSummaryBadges(),
                  const SizedBox(height: 12),
                  _buildSearchRow(theme, l10n),
                ],
              ),
            ),
          ),
          ...listAsync.when(
            data: (data) => _buildListSlivers(theme, l10n, data),
            loading: () => [_buildLoadingSliver(theme)],
            error: (error, _) => [_buildErrorSliver(theme, l10n, error)],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(ThemeData theme, AppLocalizations l10n) {
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
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l10n.filterByStatus,
          // Đang lọc → icon đổi màu để người dùng biết danh sách đã bị thu hẹp
          color: ref.watch(adminStatusFilterProvider) == 'all'
              ? null
              : theme.colorScheme.primary,
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterSheet(theme, l10n),
        ),
      ],
    );
  }

  List<Widget> _buildListSlivers(
    ThemeData theme,
    AppLocalizations l10n,
    AdminAccountListState data,
  ) {
    if (data.admins.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noAdminFound,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: data.admins.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final admin = data.admins[index];
            return _AdminCard(
              admin: admin,
              onTap: () => showAdminDetailSheet(context, admin),
            );
          },
        ),
      ),
      SliverToBoxAdapter(child: _buildListFooter(theme, l10n, data)),
    ];
  }

  Widget _buildListFooter(
    ThemeData theme,
    AppLocalizations l10n,
    AdminAccountListState data,
  ) {
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget child;
    if (data.isLoadingMore) {
      child = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (data.loadMoreFailed) {
      child = Column(
        children: [
          Text(l10n.loadMoreAdminsFailed, style: mutedStyle),
          TextButton(
            onPressed: () => ref
                .read(adminAccountListProvider.notifier)
                .loadMore(retry: true),
            child: Text(l10n.retry),
          ),
        ],
      );
    } else if (!data.hasMore) {
      child = Text(l10n.allAdminsLoaded, style: mutedStyle);
    } else {
      child = const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: child),
    );
  }

  Widget _buildLoadingSliver(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: 4,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 76,
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

  Widget _buildErrorSliver(
    ThemeData theme,
    AppLocalizations l10n,
    Object error,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                error.toString().replaceFirst('Exception: ', ''),
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
      ),
    );
  }

  void _showFilterSheet(ThemeData theme, AppLocalizations l10n) {
    final successColor = AppSemanticColors.of(context).success;
    final current = ref.read(adminStatusFilterProvider);

    void select(BuildContext sheetContext, String value) {
      ref.read(adminAccountListProvider.notifier).setStatusFilter(value);
      Navigator.pop(sheetContext);
    }

    Widget option(
      BuildContext sheetContext,
      String value,
      String label,
      Widget leading,
    ) {
      return ListTile(
        leading: leading,
        title: Text(label),
        trailing: current == value
            ? Icon(Icons.check, color: theme.colorScheme.primary)
            : null,
        onTap: () => select(sheetContext, value),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filterByStatus,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            option(
              sheetContext,
              'all',
              l10n.all,
              const Icon(Icons.groups_outlined),
            ),
            option(
              sheetContext,
              'active',
              l10n.activeStatus,
              Icon(Icons.check_circle_outline, color: successColor),
            ),
            option(
              sheetContext,
              'blocked',
              l10n.blockedStatus,
              Icon(Icons.lock_outline, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ quản trị viên trên mobile: avatar · tên (+ "Bạn") · email · trạng thái.
class _AdminCard extends StatelessWidget {
  final AdminAccountModel admin;
  final VoidCallback onTap;

  const _AdminCard({required this.admin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dimmed = !admin.isActive;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AdminAvatar(admin: admin, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminNameLine(
                      admin: admin,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: dimmed
                            ? cs.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      admin.email,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StaffStatusChip(isActive: admin.isActive),
            ],
          ),
        ),
      ),
    );
  }
}
