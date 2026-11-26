import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/users/user_charts.dart';
import 'package:smartspace_admin/ui/screen/users/user_detail_view.dart';
import 'package:smartspace_admin/ui/screen/users/user_shared_widgets.dart';

class MobileUserView extends ConsumerStatefulWidget {
  const MobileUserView({super.key});

  @override
  ConsumerState<MobileUserView> createState() => _MobileUserViewState();
}

class _MobileUserViewState extends ConsumerState<MobileUserView> {
  // Còn cách đáy < ngưỡng này (px) thì tải trang tiếp theo
  static const double _loadMoreThreshold = 400;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showStatistics = false;

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
      ref.read(userListProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(userStatisticsProvider);
    await ref.read(userListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(userListProvider);

    // Trang đầu chưa lấp đầy màn hình → không có scroll để kích hoạt load more
    ref.listen(userListProvider, (_, next) {
      if (next.hasValue && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      }
    });

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.manageUsers,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // KPI 2x2
                  const UserKpiGrid(compact: true),
                  const SizedBox(height: 8),

                  // Thống kê chi tiết — thu gọn mặc định để danh sách lên sớm
                  _buildStatisticsToggle(theme, l10n),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _showStatistics
                        ? Column(
                            children: [
                              const UserRegistrationTrendChart(
                                chartHeight: 180,
                              ),
                              const SizedBox(height: 12),
                              TopContributorsChart(
                                onUserTap: (id) => showUserDetail(context, id),
                              ),
                              const SizedBox(height: 4),
                            ],
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 12),

                  // Search + Sort
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              ref.read(userListProvider.notifier).setSearch(v),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          decoration: InputDecoration(
                            hintText: l10n.searchUsersHint,
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: l10n.sortBy,
                        icon: const Icon(Icons.sort),
                        onPressed: () => _showSortSheet(
                          context,
                          theme,
                          l10n,
                          listAsync.valueOrNull?.sort ?? UserSort.newest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 2,
                    child: listAsync.isLoading && listAsync.hasValue
                        ? const LinearProgressIndicator(minHeight: 2)
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Danh sách card
          ...listAsync.when(
            data: (data) => _buildListSlivers(context, theme, l10n, data),
            loading: () => [
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: UserListSkeleton(count: 5, itemHeight: 84),
                ),
              ),
            ],
            error: (error, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: UserErrorState(
                    error: error,
                    onRetry: () =>
                        ref.read(userListProvider.notifier).refresh(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              child: Icon(
                Icons.expand_more,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListSlivers(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    UserListState data,
  ) {
    if (data.users.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: UserEmptyState(isSearching: data.search != null),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: data.users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = data.users[index];
            return UserCard(
              user: user,
              onTap: () => showUserDetail(context, user.id),
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
    UserListState data,
  ) {
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
          Text(
            l10n.loadMoreFailed,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(userListProvider.notifier).loadMore(retry: true),
            child: Text(l10n.retry),
          ),
        ],
      );
    } else if (!data.hasMore) {
      child = Text(
        l10n.allUsersLoaded,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      child = const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: child),
    );
  }

  void _showSortSheet(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    UserSort current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.sortBy,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final sort in UserSort.values)
                ListTile(
                  title: Text(sortLabel(l10n, sort)),
                  trailing: sort == current
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  selected: sort == current,
                  onTap: () {
                    ref.read(userListProvider.notifier).setSort(sort);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
