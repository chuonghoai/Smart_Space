import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/features/users/models/admin_user_model.dart';
import 'package:smartspace_admin/features/users/models/user_statistics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/dashboard/kpi_card.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';

/// Định dạng ngày dùng chung cho màn Quản lý người dùng.
String formatUserDate(DateTime? date) =>
    date == null ? '—' : DateFormat('dd/MM/yyyy').format(date);

String sortLabel(AppLocalizations l10n, UserSort sort) => switch (sort) {
  UserSort.newest => l10n.sortNewest,
  UserSort.oldest => l10n.sortOldest,
  UserSort.name => l10n.sortByName,
};

/// Chip "Đã khoá" — chỉ hiển thị khi tài khoản bị khoá.
class UserBlockedChip extends StatelessWidget {
  const UserBlockedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppLocalizations.of(context)!.blockedStatus,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 4 KPI của màn Quản lý người dùng.
class UserKpiGrid extends ConsumerWidget {
  final bool compact;
  const UserKpiGrid({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(userStatisticsProvider);

    return statsAsync.when(
      data: (stats) => _buildGrid(context, l10n, stats),
      loading: () => _buildGrid(context, l10n, null),
      error: (_, _) => InlineErrorBanner(
        message: l10n.statisticsLoadFailed,
        onRetry: () => ref.invalidate(userStatisticsProvider),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    UserStatisticsModel? stats,
  ) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    String value(int? v) => v == null ? '—' : formatCount(context, v);

    return KpiGrid(
      compact: compact,
      cards: [
        KpiCard(
          compact: compact,
          icon: Icons.people_outline,
          iconColor: theme.colorScheme.primary,
          label: l10n.totalUsers,
          value: value(stats?.totalUsers),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.person_add_alt_outlined,
          iconColor: semantic.info,
          label: l10n.newUsers30Days,
          value: value(stats?.newUsers),
          footnote: KpiFootnote.change(
            context,
            current: stats?.newUsers,
            previous: stats?.newUsersPrevious,
            // Tăng người dùng mới là tín hiệu tốt → có màu semantic
            tone: ChangeTone.higherIsBetter,
          ),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.campaign_outlined,
          iconColor: semantic.success,
          label: l10n.activeReporters30Days,
          value: value(stats?.activeReporters),
          footnote: stats?.activeReporterRatio == null
              ? null
              : KpiFootnote(
                  l10n.percentOfUsers(
                    (stats!.activeReporterRatio! * 100).toStringAsFixed(1),
                  ),
                ),
        ),
        KpiCard(
          compact: compact,
          icon: Icons.description_outlined,
          iconColor: theme.colorScheme.secondary,
          label: l10n.reports30Days,
          value: value(stats?.reports),
          // Số phản ánh tăng/giảm không mang nghĩa tốt/xấu → giữ màu trung tính
          footnote: KpiFootnote.change(
            context,
            current: stats?.reports,
            previous: stats?.reportsPrevious,
          ),
        ),
      ],
    );
  }
}

/// Card người dùng (Mobile).
class UserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTap;

  const UserCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PersonAvatar(
                avatarUrl: user.avatarUrl,
                name: user.fullName,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName.isEmpty ? user.email : user.fullName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isBlocked) ...[
                          const SizedBox(width: 6),
                          const UserBlockedChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: mutedStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: user.reportCount > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.reportCountLabel(user.reportCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: user.reportCount > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            l10n.joinedOn(formatUserDate(user.createdAt)),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phân trang dạng cửa sổ: 1 … 4 5 6 … 20 — không tràn khi có nhiều trang.
class UserPaginationControls extends ConsumerWidget {
  final UserListState data;
  const UserPaginationControls({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(userListProvider.notifier);
    final current = data.currentPage;
    final total = data.totalPages;

    final from = data.users.isEmpty ? 0 : (current - 1) * data.pageSize + 1;
    final to = from == 0 ? 0 : from + data.users.length - 1;

    return Row(
      children: [
        Text(
          l10n.paginationSummary(from, to, data.totalElements),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (total > 1) ...[
          IconButton(
            tooltip: MaterialLocalizations.of(context).previousPageTooltip,
            icon: const Icon(Icons.chevron_left),
            onPressed: current > 1
                ? () => notifier.goToPage(current - 1)
                : null,
          ),
          for (final page in _visiblePages(current, total))
            page == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '…',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _PageButton(
                    page: page,
                    isCurrent: page == current,
                    onTap: () => notifier.goToPage(page),
                  ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).nextPageTooltip,
            icon: const Icon(Icons.chevron_right),
            onPressed: current < total
                ? () => notifier.goToPage(current + 1)
                : null,
          ),
        ],
      ],
    );
  }

  /// null = dấu "…"
  static List<int?> _visiblePages(int current, int total) {
    if (total <= 7) return List.generate(total, (i) => i + 1);
    final pages = <int?>[1];
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    if (start > 2) pages.add(null);
    for (var p = start; p <= end; p++) {
      pages.add(p);
    }
    if (end < total - 1) pages.add(null);
    pages.add(total);
    return pages;
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PageButton({
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isCurrent ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isCurrent ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: TextStyle(
                color: isCurrent
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown sắp xếp (Web).
class UserSortDropdown extends ConsumerWidget {
  final UserSort value;
  const UserSortDropdown({super.key, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserSort>(
          value: value,
          icon: const Icon(Icons.sort, size: 18),
          items: [
            for (final sort in UserSort.values)
              DropdownMenuItem(value: sort, child: Text(sortLabel(l10n, sort))),
          ],
          onChanged: (v) {
            if (v != null) ref.read(userListProvider.notifier).setSort(v);
          },
        ),
      ),
    );
  }
}

/// Trạng thái rỗng của danh sách.
class UserEmptyState extends StatelessWidget {
  final bool isSearching;
  const UserEmptyState({super.key, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? l10n.noUsersFound : l10n.noUsersInSystem,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái lỗi toàn khối, có nút thử lại.
class UserErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const UserErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final message = error.toString().replaceFirst('Exception: ', '');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Khung xương (skeleton) khi tải danh sách lần đầu.
class UserListSkeleton extends StatelessWidget {
  final int count;
  final double itemHeight;
  const UserListSkeleton({super.key, this.count = 6, this.itemHeight = 64});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
