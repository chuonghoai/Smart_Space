import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class WebSidebar extends ConsumerWidget {
  const WebSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.countModel?.notifNumber ?? 0;

    return Container(
      width: 250,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.smartSpaceAppName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: Icons.home_outlined,
                  label: l10n.home,
                  onTap: () {
                    context.go(RouterPath.home);
                  },
                  isSelected: true,
                ),
                _SidebarItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.notifications,
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    // TODO: Navigate to Notifications
                  },
                ),
                _SidebarItem(
                  icon: Icons.report_outlined,
                  label: l10n.myReports,
                  onTap: () {
                    // TODO: Navigate to My Reports
                  },
                ),
                _SidebarItem(
                  icon: Icons.map_outlined,
                  label: l10n.map,
                  onTap: () {
                    // TODO: Navigate to Map
                  },
                ),
                _SidebarItem(
                  icon: Icons.article_outlined,
                  label: l10n.news, // Fixed 'title' to 'label'
                  onTap: () {
                    // TODO: Navigate to news
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1),
                ),

                // Secondary Navigation
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: l10n.settings,
                  onTap: () {
                    context.push(RouterPath.settings);
                  },
                ),
                _SidebarItem(
                  icon: Icons.help_outline,
                  label: l10n.instructions,
                  onTap: () {
                    // TODO: Navigate to instructions
                  },
                ),
                _SidebarItem(
                  icon: Icons.info_outline,
                  label: l10n.aboutApp,
                  onTap: () {
                    // TODO: Navigate to About application
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarItem(
              icon: Icons.logout,
              label: l10n.logout,
              textColor: theme.colorScheme.error,
              iconColor: theme.colorScheme.error,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.textColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ??
            (isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color:
              textColor ??
              (isSelected ? primaryColor : theme.colorScheme.onSurface),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: primaryColor.withOpacity(0.08),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
