// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:smartspace_staff/features/notifications/providers/notification_provider.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/app_router.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';
import 'package:smartspace_staff/ui/shared/image/app_network_image.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.countModel?.notifNumber ?? 0;
    // Sidebar is only mounted inside MobileHomeScreen, so the home provider is alive here.
    final stats = ref.watch(
      homeControllerProvider.select((state) => state.statistics),
    );

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
                    trailing: _CountBadge(count: unreadCount, highlight: true),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouterPath.notifications);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    label: l10n.routeMap,
                    onTap: () {
                      context.push(RouterPath.map);
                    },
                    isSelected: false,
                  ),
                  _SidebarItem(
                    icon: Icons.article_outlined,
                    label: l10n.news,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouterPath.news);
                    },
                  ),

                  // My Work
                  _SidebarSectionHeader(label: l10n.myWorkDashboard),
                  _SidebarItem(
                    icon: Icons.assignment_outlined,
                    label: l10n.filterAll,
                    trailing: _CountBadge(count: stats?.total ?? 0),
                    onTap: () => _openMyWork(context, 'all'),
                  ),
                  _SidebarItem(
                    icon: Icons.autorenew,
                    label: l10n.reportStatusProcessing,
                    trailing: _CountBadge(count: stats?.processing ?? 0),
                    onTap: () => _openMyWork(context, 'processing'),
                  ),
                  _SidebarItem(
                    icon: Icons.replay_rounded,
                    label: l10n.rehandling,
                    trailing: _CountBadge(
                      count: stats?.rehandling ?? 0,
                      highlight: true,
                    ),
                    onTap: () => _openMyWork(context, 'rehandling'),
                  ),
                  _SidebarItem(
                    icon: Icons.task_alt,
                    label: l10n.reportStatusProcessed,
                    onTap: () => _openMyWork(context, 'resolved'),
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

void _openMyWork(BuildContext context, String filter) {
  Navigator.pop(context);
  context.push(
    Uri(
      path: RouterPath.allReports,
      queryParameters: {'filter': filter},
    ).toString(),
  );
}

class _SidebarSectionHeader extends StatelessWidget {
  final String label;

  const _SidebarSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  /// Uses the error color to draw attention (unread notifications, re-handling tasks).
  final bool highlight;

  const _CountBadge({required this.count, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final background = highlight ? colorScheme.error : colorScheme.primaryContainer;
    final foreground = highlight ? colorScheme.onError : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
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
