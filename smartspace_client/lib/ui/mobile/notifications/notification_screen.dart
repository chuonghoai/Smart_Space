import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/features/notifications/models/notification_model.dart';
import 'package:smartspace_client/features/notifications/services/notification_router.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).fetchNotifications(loadMore: true);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    if (notification.actionData != null) {
      NotificationRouter.handleAction(notification.actionData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routeNotifications),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
            child: Text(l10n.markAllAsRead, style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReadFilter(context, state),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(notificationProvider.notifier).fetchNotifications();
              },
              child: state.isLoadingNotifications && state.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.notificationsError != null && state.notifications.isEmpty
                  ? Center(child: Text(state.notificationsError!))
                  : state.notifications.isEmpty
                  ? _buildEmptyState(context, state)
                  : ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == state.notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = state.notifications[index];
                        return ListTile(
                          tileColor: item.isRead ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.08),
                          onTap: () => _handleNotificationTap(item),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? NetworkImage(item.imageUrl!)
                                : null,
                            child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                                ? Icon(Icons.notifications, color: theme.colorScheme.onSurfaceVariant)
                                : null,
                          ),
                          title: Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                              color: item.isRead
                                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(item.createdAt, l10n),
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          trailing: !item.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Một hàng điều khiển: Tất cả / Chưa đọc. Số trên "Chưa đọc" là số badge — cùng tập thông báo
  /// mà bộ lọc trả về (thông báo cá nhân chưa đọc).
  Widget _buildReadFilter(BuildContext context, NotificationState state) {
    final l10n = AppLocalizations.of(context)!;
    final unread = state.countModel?.notifNumber ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l10n.mapFilterAll)),
            ButtonSegment(
              value: true,
              label: Text(
                unread > 0
                    ? l10n.notificationFilterUnreadCount(unread > 99 ? '99+' : '$unread')
                    : l10n.notificationFilterUnread,
              ),
            ),
          ],
          selected: {state.unreadOnly},
          onSelectionChanged: (selection) => ref.read(notificationProvider.notifier).setUnreadOnly(selection.first),
        ),
      ),
    );
  }

  /// Trống: nằm trong vùng cuộn để vẫn kéo làm mới được; ở "Chưa đọc" gợi ý quay về Tất cả.
  Widget _buildEmptyState(BuildContext context, NotificationState state) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 96),
        Icon(
          state.unreadOnly ? Icons.done_all_rounded : Icons.notifications_none_rounded,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          state.unreadOnly ? l10n.allNotificationsRead : l10n.emptyNotification,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        if (state.unreadOnly) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => ref.read(notificationProvider.notifier).setUnreadOnly(false),
              child: Text(l10n.viewAllNotifications),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}${l10n.dayAgo}';
    if (diff.inHours > 0) return '${diff.inHours}${l10n.hourAgo}';
    if (diff.inMinutes > 0) return '${diff.inMinutes}${l10n.minuteAgo}';
    return l10n.justNow;
  }
}
