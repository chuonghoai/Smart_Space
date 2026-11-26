import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/admin_accounts/application/admin_account_providers.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/staff/staff_shared_widgets.dart'
    show StaffDetailRow, StaffStatusChip;

// ─────────────────────────────────────────────────────────────────────────────
// Format helpers
// ─────────────────────────────────────────────────────────────────────────────

String formatAdminDate(DateTime? date) =>
    date == null ? '—' : DateFormat('dd/MM/yyyy').format(date.toLocal());

String _formatActivityTime(String? raw) {
  final date = DateTime.tryParse(raw ?? '');
  return date == null ? '' : DateFormat('HH:mm - dd/MM/yyyy').format(date.toLocal());
}

/// Lý do không được khóa/mở khóa [admin] (null = được phép). Backend cũng kiểm tra lại.
String? adminToggleBlockedReason(
  AppLocalizations l10n,
  AdminAccountListState state,
  AdminAccountModel admin,
) {
  if (state.canToggle(admin)) return null;
  return admin.isCurrentUser ? l10n.cannotLockSelf : l10n.cannotLockLastAdmin;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small building blocks
// ─────────────────────────────────────────────────────────────────────────────

/// Avatar quản trị viên — ảnh nếu có, ngược lại chữ cái đầu.
class AdminAvatar extends StatelessWidget {
  final AdminAccountModel admin;
  final double radius;

  const AdminAvatar({super.key, required this.admin, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = admin.avatarUrl;
    final name = admin.displayName;
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
                color: cs.primary,
              ),
            )
          : null,
    );
  }
}

/// Nhãn "Bạn" cạnh tên tài khoản đang đăng nhập.
class AdminYouBadge extends StatelessWidget {
  const AdminYouBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        AppLocalizations.of(context)!.youBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tên + nhãn "Bạn" (nếu là mình) trên một dòng, tên co lại khi hẹp.
class AdminNameLine extends StatelessWidget {
  final AdminAccountModel admin;
  final TextStyle? style;

  const AdminNameLine({super.key, required this.admin, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            admin.displayName,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (admin.isCurrentUser) ...[
          const SizedBox(width: 8),
          const AdminYouBadge(),
        ],
      ],
    );
  }
}

/// Thống kê dạng badge: Tổng · Hoạt động · Đã khoá. Bấm một badge để lọc danh sách
/// (bấm lại badge đang chọn → bỏ lọc). Đồng bộ với dropdown / filter sheet qua
/// [adminStatusFilterProvider].
class AdminSummaryBadges extends ConsumerWidget {
  const AdminSummaryBadges({super.key});

  // Giữ chỗ khi chưa có số liệu để layout không nhảy
  static const double _height = 34;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final successColor = AppSemanticColors.of(context).success;
    final summary = ref.watch(
      adminAccountListProvider.select((s) => s.valueOrNull?.summary),
    );
    final filter = ref.watch(adminStatusFilterProvider);

    if (summary == null) return const SizedBox(height: _height);

    void select(String value) {
      // Bấm lại badge đang chọn (trừ "Tổng") → bỏ lọc
      final next = (filter == value) ? 'all' : value;
      ref.read(adminAccountListProvider.notifier).setStatusFilter(next);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryBadge(
          label: l10n.adminTotalBadge,
          count: summary.total,
          tone: cs.onSurfaceVariant,
          background: cs.surfaceContainerHighest,
          selected: filter == 'all',
          onTap: () => select('all'),
        ),
        _SummaryBadge(
          label: l10n.activeStatus,
          count: summary.active,
          tone: successColor,
          background: successColor.withValues(alpha: 0.12),
          selected: filter == 'active',
          onTap: () => select('active'),
        ),
        _SummaryBadge(
          label: l10n.blockedStatus,
          count: summary.blocked,
          tone: cs.error,
          background: cs.error.withValues(alpha: 0.1),
          selected: filter == 'blocked',
          onTap: () => select('blocked'),
        ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color tone;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.tone,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: StadiumBorder(
          // Viền luôn có (trong suốt khi không chọn) để kích thước badge không đổi
          side: BorderSide(
            color: selected ? tone : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: textTheme.titleSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel (web side panel / dialog / mobile bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

/// Thông tin + hoạt động gần đây + nút khóa/mở khóa của một quản trị viên.
class AdminDetailPanel extends ConsumerWidget {
  final AdminAccountModel admin;

  /// Gọi trước khi mở dialog xác nhận (vd: đóng bottom sheet trên mobile).
  final VoidCallback? onBeforeToggle;

  const AdminDetailPanel({super.key, required this.admin, this.onBeforeToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listState = ref.watch(adminAccountListProvider).valueOrNull;
    final blockedReason = listState == null
        ? null
        : adminToggleBlockedReason(l10n, listState, admin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AdminAvatar(admin: admin, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminNameLine(
                    admin: admin,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaffStatusChip(isActive: admin.isActive),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StaffDetailRow(icon: Icons.email_outlined, text: admin.email),
        const SizedBox(height: 12),
        StaffDetailRow(
          icon: Icons.phone_outlined,
          text: admin.phoneNumber ?? '—',
        ),
        const SizedBox(height: 12),
        StaffDetailRow(
          icon: Icons.event_outlined,
          text: l10n.joinedOn(formatAdminDate(admin.createdAt)),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          l10n.recentActivity,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _AdminActivityList(adminId: admin.id),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => showAdminActivityHistory(context, admin),
          icon: const Icon(Icons.history),
          label: Text(l10n.activityHistory),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.outline),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        _AdminToggleButton(
          admin: admin,
          blockedReason: blockedReason,
          onPressed: () {
            onBeforeToggle?.call();
            confirmToggleAdminStatus(context, ref, admin);
          },
        ),
      ],
    );
  }
}

class _AdminActivityList extends ConsumerWidget {
  final String adminId;

  const _AdminActivityList({required this.adminId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activitiesAsync = ref.watch(adminActivitiesProvider(adminId));

    return activitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              l10n.activityLoadFailed,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(adminActivitiesProvider(adminId)),
            child: Text(l10n.retry),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          // Giữ khung của section, chỉ báo trống
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.noRecentActivity,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(height: 1, color: theme.dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(items[i].message, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      _formatActivityTime(items[i].createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AdminToggleButton extends StatelessWidget {
  final AdminAccountModel admin;
  final String? blockedReason;
  final VoidCallback onPressed;

  const _AdminToggleButton({
    required this.admin,
    required this.blockedReason,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final color = admin.isActive ? cs.error : cs.primary;
    final enabled = blockedReason == null;

    final button = OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(admin.isActive ? Icons.lock_outline : Icons.lock_open),
      label: Text(admin.isActive ? l10n.lockAccount : l10n.unlockAccount),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: enabled ? color : cs.onSurface.withValues(alpha: 0.12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (enabled) return button;
    // Nút bị khóa: hiện lý do ngay bên dưới (tooltip không dùng được trên cảm ứng)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          blockedReason!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Mobile: bottom sheet chi tiết; phần nội dung cuộn được khi màn hình thấp.
void showAdminDetailSheet(BuildContext context, AdminAccountModel admin) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AdminDetailPanel(
                admin: admin,
                onBeforeToggle: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Web hẹp (không đủ chỗ cho panel bên phải): dialog chi tiết.
void showAdminDetailDialog(BuildContext context, AdminAccountModel admin) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AdminDetailPanel(
            admin: admin,
            onBeforeToggle: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity history (full, paginated)
// ─────────────────────────────────────────────────────────────────────────────

/// Mở toàn bộ lịch sử hoạt động của [admin]: dialog trên màn rộng, bottom sheet trên mobile.
void showAdminActivityHistory(BuildContext context, AdminAccountModel admin) {
  final isWide = MediaQuery.sizeOf(context).width >= 640;
  if (isWide) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight.clamp(320, 720)),
          child: _AdminActivityHistoryView(admin: admin),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _AdminActivityHistoryView(
        admin: admin,
        scrollController: scrollController,
        showDragHandle: true,
      ),
    ),
  );
}

class _AdminActivityHistoryView extends ConsumerStatefulWidget {
  final AdminAccountModel admin;

  /// Bottom sheet truyền controller của DraggableScrollableSheet; dialog tự tạo.
  final ScrollController? scrollController;
  final bool showDragHandle;

  const _AdminActivityHistoryView({
    required this.admin,
    this.scrollController,
    this.showDragHandle = false,
  });

  @override
  ConsumerState<_AdminActivityHistoryView> createState() =>
      _AdminActivityHistoryViewState();
}

class _AdminActivityHistoryViewState
    extends ConsumerState<_AdminActivityHistoryView> {
  // Còn cách đáy < ngưỡng này (px) thì tải trang tiếp theo
  static const double _loadMoreThreshold = 300;

  ScrollController? _ownController;
  ScrollController get _controller =>
      widget.scrollController ?? (_ownController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller.removeListener(_maybeLoadMore);
    _ownController?.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < _loadMoreThreshold) {
      ref.read(adminActivityHistoryProvider(widget.admin.id).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = adminActivityHistoryProvider(widget.admin.id);
    final historyAsync = ref.watch(provider);

    // Trang đầu chưa lấp đầy khung → không có scroll để kích hoạt tải thêm
    ref.listen(provider, (_, next) {
      if (next.hasValue && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeLoadMore();
        });
      }
    });

    final header = Padding(
      padding: EdgeInsets.fromLTRB(24, widget.showDragHandle ? 12 : 20, 12, 12),
      child: Column(
        children: [
          if (widget.showDragHandle)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Row(
            children: [
              Icon(Icons.history, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activityHistory,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.admin.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.closeAction,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );

    final Widget body = historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: cs.error),
              const SizedBox(height: 12),
              Text(l10n.activityLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(provider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.noActivitiesFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          itemCount: data.items.length + 1, // +1: footer
          separatorBuilder: (_, index) => index == data.items.length - 1
              ? const SizedBox.shrink()
              : Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (_, index) {
            if (index == data.items.length) return _buildFooter(l10n, theme, data);
            final item = data.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.message, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    _formatActivityTime(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return Material(
      color: cs.surface,
      child: Column(
        children: [
          header,
          const Divider(height: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildFooter(
    AppLocalizations l10n,
    ThemeData theme,
    AdminActivityHistoryState data,
  ) {
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Widget child;
    if (data.isLoadingMore) {
      child = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (data.loadMoreFailed) {
      child = Column(
        children: [
          Text(l10n.loadMoreActivitiesFailed, style: mutedStyle),
          TextButton(
            onPressed: () => ref
                .read(adminActivityHistoryProvider(widget.admin.id).notifier)
                .loadMore(retry: true),
            child: Text(l10n.retry),
          ),
        ],
      );
    } else if (!data.hasMore) {
      child = Text(l10n.allActivitiesLoaded, style: mutedStyle);
    } else {
      child = const SizedBox(height: 24);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lock / unlock
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog xác nhận khóa / mở khóa; kết quả báo bằng SnackBar trên [parentContext].
void confirmToggleAdminStatus(
  BuildContext parentContext,
  WidgetRef ref,
  AdminAccountModel admin,
) {
  final l10n = AppLocalizations.of(parentContext)!;
  final messenger = ScaffoldMessenger.of(parentContext);
  final notifier = ref.read(adminAccountListProvider.notifier);

  showDialog<void>(
    context: parentContext,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(admin.isActive ? l10n.lockAccount : l10n.unlockAccount),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            admin.isActive
                ? l10n.lockAdminConfirm(admin.displayName)
                : l10n.unlockAdminConfirm(admin.displayName),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final error = await notifier.toggleStatus(admin);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    error == null
                        ? l10n.updateStatusSuccess
                        : (error.isNotEmpty ? error : l10n.updateStatusFailed),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: admin.isActive ? cs.error : cs.primary,
              foregroundColor: admin.isActive ? cs.onError : cs.onPrimary,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Create admin
// ─────────────────────────────────────────────────────────────────────────────

/// Mở form thêm quản trị viên. Thành công → dialog xác nhận đã gửi mật khẩu qua email.
Future<void> showAdminFormDialog(BuildContext context) async {
  final isWide = MediaQuery.sizeOf(context).width >= 640;

  final String? createdEmail;
  if (isWide) {
    createdEmail = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const SizedBox(width: 480, child: _AdminForm(isWide: true)),
      ),
    );
  } else {
    createdEmail = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AdminForm(isWide: false),
    );
  }

  if (createdEmail == null || !context.mounted) return;
  await _showAdminCreatedDialog(context, createdEmail);
}

Future<void> _showAdminCreatedDialog(BuildContext context, String email) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      final theme = Theme.of(dialogContext);
      final cs = theme.colorScheme;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(
          Icons.mark_email_read_outlined,
          color: AppSemanticColors.of(dialogContext).success,
          size: 40,
        ),
        title: Text(l10n.adminCreatedTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.staffCreatedCredentialsSent,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.adminCreatedCheckInboxHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.closeAction),
          ),
        ],
      );
    },
  );
}

class _AdminForm extends ConsumerStatefulWidget {
  final bool isWide;

  const _AdminForm({required this.isWide});

  @override
  ConsumerState<_AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends ConsumerState<_AdminForm> {
  // Đồng bộ với validation của backend (CreateAdminRequest)
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9]{8,15}$');
  static const _maxNameLength = 100;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();
    String? error;
    try {
      error = await ref.read(adminAccountListProvider.notifier).createAdmin(
            fullName: _nameCtrl.text.trim(),
            email: email,
            phone: _phoneCtrl.text.trim(),
          );
    } catch (_) {
      error = '';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Trả email về cho showAdminFormDialog để hiện dialog thành công trên màn hình cha
      Navigator.pop(context, email);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error.isNotEmpty ? error : l10n.addAdminFailed)),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final submitButton = FilledButton(
      onPressed: _isLoading ? null : _submit,
      style: widget.isWide
          ? null
          : FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
            )
          : Text(l10n.createAdminAction),
    );
    final cancelButton = TextButton(
      onPressed: _isLoading ? null : () => Navigator.pop(context),
      child: Text(l10n.cancel),
    );

    return Padding(
      // Đẩy form lên trên bàn phím ở mobile
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isWide)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Text(
                l10n.addNewAdmin,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                maxLength: _maxNameLength,
                decoration: _decoration('${l10n.fullname} *', Icons.person_outline)
                    .copyWith(counterText: ''),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return l10n.fullnameRequired;
                  if (value.length > _maxNameLength) return l10n.fullnameTooLong;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _decoration('${l10n.email} *', Icons.email_outlined),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return l10n.emailRequired;
                  if (!_emailPattern.hasMatch(value)) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _decoration(l10n.phone, Icons.phone_outlined),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null;
                  return _phonePattern.hasMatch(value) ? null : l10n.invalidPhoneFormat;
                },
              ),
              const SizedBox(height: 24),
              if (widget.isWide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [cancelButton, const SizedBox(width: 8), submitButton],
                )
              else ...[
                submitButton,
                const SizedBox(height: 8),
                cancelButton,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
