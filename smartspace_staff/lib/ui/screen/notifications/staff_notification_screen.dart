import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/features/notifications/models/notification_model.dart';

class StaffNotificationScreen extends ConsumerStatefulWidget {
  const StaffNotificationScreen({super.key});

  @override
  ConsumerState<StaffNotificationScreen> createState() => _StaffNotificationScreenState();
}

class _StaffNotificationScreenState extends ConsumerState<StaffNotificationScreen> {
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
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }
    
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

    final appBar = AppBar(
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
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: appBar,
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
                                  _formatTime(item.createdAt, l10n),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: !item.isRead ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ) : null,
                          );
                        },
                      ),
      ),
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} ${l10n.dayAgo}';
    if (diff.inHours > 0) return '${diff.inHours} ${l10n.hourAgo}';
    if (diff.inMinutes > 0) return '${diff.inMinutes} ${l10n.minuteAgo}';
    return l10n.justNow;
  }
}
