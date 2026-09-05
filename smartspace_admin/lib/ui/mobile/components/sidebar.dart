// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/app_router.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.countModel?.notifNumber ?? 0;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<UserModel?>(
              future: userStorageService.getUser(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      AppNetworkImage(
                        url: user?.avatarUrl,
                        width: 48,
                        height: 48,
                        isCircle: true,
                        errorWidget: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullname ?? l10n.user,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? 'unknow@gmail.com',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),

            // Primary Navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                      Navigator.pop(context);
                      // TODO: Navigate to Notifications
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.report_outlined,
                    label: l10n.myReports,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to My Reports
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    label: l10n.map,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to Map
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.article_outlined,
                    label: l10n.news,
                    onTap: () {
                      Navigator.pop(context);
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
                      Navigator.pop(context);
                      context.push(RouterPath.settings);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.help_outline,
                    label: l10n.instructions,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to instructions
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.info_outline,
                    label: l10n.aboutApp,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to About application
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _SidebarItem(
                icon: Icons.logout,
                label: l10n.logout,
                textColor: theme.colorScheme.error,
                iconColor: theme.colorScheme.error,
                onTap: () async {
                  Navigator.pop(context);
                  await authService.logout();
                  appRouter.go(RouterPath.login);
                },
              ),
            ),
          ],
        ),
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
