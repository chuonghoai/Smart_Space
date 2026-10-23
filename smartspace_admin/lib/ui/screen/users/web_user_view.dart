import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/users/user_charts.dart';
import 'package:smartspace_admin/ui/screen/users/user_detail_view.dart';
import 'package:smartspace_admin/ui/screen/users/user_shared_widgets.dart';

class WebUserView extends ConsumerStatefulWidget {
  const WebUserView({super.key});

  @override
  ConsumerState<WebUserView> createState() => _WebUserViewState();
}

class _WebUserViewState extends ConsumerState<WebUserView> {
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
    final listAsync = ref.watch(userListProvider);
    final totalUsers = ref.watch(
      userStatisticsProvider.select((s) => s.valueOrNull?.totalUsers),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            totalUsers == null
                ? l10n.manageUsers
                : '${l10n.manageUsers} · ${formatUserCount(context, totalUsers)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // KPI
          const UserKpiGrid(),
          const SizedBox(height: 20),

          // Charts — 2/3 trend + 1/3 top contributors, xếp dọc khi hẹp
          LayoutBuilder(
            builder: (context, constraints) {
              final trend = const UserRegistrationTrendChart();
              final top = TopContributorsChart(
                onUserTap: (id) => showUserDetail(context, id),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [trend, const SizedBox(height: 16), top],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: trend),
                  const SizedBox(width: 16),
                  Expanded(child: top),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Search + Sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(userListProvider.notifier).setSearch(v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchUsersHint,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              UserSortDropdown(
                value: listAsync.valueOrNull?.sort ?? UserSort.newest,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          listAsync.when(
            data: (data) => _buildTable(context, l10n, theme, data, listAsync),
            loading: () => const UserListSkeleton(),
            error: (error, _) => UserErrorState(
              error: error,
              onRetry: () => ref.read(userListProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    UserListState data,
    AsyncValue<UserListState> listAsync,
  ) {
    if (data.users.isEmpty) {
      return UserEmptyState(isSearching: data.search != null);
    }

    // Cột sort: 0 = Người dùng (tên), 3 = Ngày tham gia
    final sortColumnIndex = data.sort == UserSort.name ? 0 : 3;
    final sortAscending = data.sort != UserSort.newest;
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        if (listAsync.isLoading)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerLow,
                  ),
                  headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 68,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Text(l10n.users),
                      onSort: (_, _) => ref
                          .read(userListProvider.notifier)
                          .setSort(UserSort.name),
                    ),
                    DataColumn(label: Text(l10n.phoneNumber)),
                    DataColumn(label: Text(l10n.reportsColumn), numeric: true),
                    DataColumn(
                      label: Text(l10n.joinedDate),
                      onSort: (_, _) => ref
                          .read(userListProvider.notifier)
                          .setSort(
                            data.sort == UserSort.newest
                                ? UserSort.oldest
                                : UserSort.newest,
                          ),
                    ),
                    const DataColumn(label: SizedBox.shrink()),
                  ],
                  rows: data.users.map((user) {
                    void open() => showUserDetail(context, user.id);
                    return DataRow(
                      onSelectChanged: (_) => open(),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              UserAvatar(
                                avatarUrl: user.avatarUrl,
                                name: user.fullName,
                                radius: 18,
                              ),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.fullName.isEmpty
                                                ? '—'
                                                : user.fullName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (user.isBlocked) ...[
                                          const SizedBox(width: 6),
                                          const UserBlockedChip(),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      user.email,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            (user.phoneNumber?.isNotEmpty ?? false)
                                ? user.phoneNumber!
                                : '—',
                            style: mutedStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${user.reportCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: user.reportCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(formatUserDate(user.createdAt), style: mutedStyle),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: l10n.viewDetails,
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: open,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        UserPaginationControls(data: data),
      ],
    );
  }
}
