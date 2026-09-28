import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_client/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/features/notifications/models/notification_model.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).fetchNotifications(loadMore: true);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.actionData != null) {
       final type = notification.actionData!.type;
       final id = notification.actionData!.payload['id'] ?? notification.actionData!.payload['reportId'];
       if ((type == 'REPORT' || type == 'REPORT_DETAIL') && id != null) {
          context.push(RouterPath.reportDetail.replaceAll(':id', id.toString()));
       }
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
            child: Text(
              l10n.markAllAsRead,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).fetchNotifications();
        },
        child: state.isLoadingNotifications && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.notificationsError != null && state.notifications.isEmpty
                ? Center(child: Text(state.notificationsError!))
                : state.notifications.isEmpty
                    ? Center(child: Text(l10n.emptyNotification))
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
                                color: item.isRead ? theme.colorScheme.onSurface.withOpacity(0.7) : theme.colorScheme.onSurface,
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
                                  _formatTime(item.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
