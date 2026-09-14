// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                    icon: Icons.dashboard_outlined,
                    label: l10n.adminOverview,
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
                    label: l10n.manageReports,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to Manage Reports
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    label: l10n.spaceMap,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to Space Map
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    label: l10n.manageUsers,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to Manage Users
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.badge_outlined,
                    label: l10n.manageStaffs,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouterPath.staffManagement);
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

/// Web sidebar — fixed, inline, supports expanded/collapsed.
class WebSidebar extends ConsumerWidget {
  final bool isExpanded;
  const WebSidebar({super.key, required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.countModel?.notifNumber ?? 0;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Column(
      children: [
        // User info
        if (isExpanded)
          FutureBuilder<UserModel?>(
            future: userStorageService.getUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    AppNetworkImage(
                      url: user?.avatarUrl,
                      width: 40,
                      height: 40,
                      isCircle: true,
                      errorWidget: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullname ?? l10n.user,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
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
        if (isExpanded) const Divider(height: 1),

        // Navigation items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _WebSidebarItem(
                icon: Icons.dashboard_outlined,
                label: l10n.adminOverview,
                isExpanded: isExpanded,
                isSelected: currentPath == RouterPath.home,
                onTap: () => context.go(RouterPath.home),
              ),
              _WebSidebarItem(
                icon: Icons.notifications_outlined,
                label: l10n.notifications,
                isExpanded: isExpanded,
                isSelected: false,
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () {
                  // TODO: Navigate to Notifications
                },
              ),
              _WebSidebarItem(
                icon: Icons.report_outlined,
                label: l10n.manageReports,
                isExpanded: isExpanded,
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to Manage Reports
                },
              ),
              _WebSidebarItem(
                icon: Icons.map_outlined,
                label: l10n.spaceMap,
                isExpanded: isExpanded,
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to Space Map
                },
              ),
              _WebSidebarItem(
                icon: Icons.people_outline,
                label: l10n.manageUsers,
                isExpanded: isExpanded,
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to Manage Users
                },
              ),
              _WebSidebarItem(
                icon: Icons.badge_outlined,
                label: l10n.manageStaffs,
                isExpanded: isExpanded,
                isSelected: currentPath == RouterPath.staffManagement,
                onTap: () => context.go(RouterPath.staffManagement),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),

              _WebSidebarItem(
                icon: Icons.settings_outlined,
                label: l10n.settings,
                isExpanded: isExpanded,
                isSelected: currentPath == RouterPath.settings,
                onTap: () => context.go(RouterPath.settings),
              ),
              _WebSidebarItem(
                icon: Icons.help_outline,
                label: l10n.instructions,
                isExpanded: isExpanded,
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to instructions
                },
              ),
              _WebSidebarItem(
                icon: Icons.info_outline,
                label: l10n.aboutApp,
                isExpanded: isExpanded,
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to About
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),
        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _WebSidebarItem(
            icon: Icons.logout,
            label: l10n.logout,
            isExpanded: isExpanded,
            isSelected: false,
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            onTap: () async {
              await authService.logout();
              appRouter.go(RouterPath.login);
            },
          ),
        ),
      ],
    );
  }
}

/// Item cho web sidebar — hỗ trợ expanded (icon + text) và collapsed (icon only + tooltip)
class _WebSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final int? badge;

  const _WebSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final effectiveIconColor =
        iconColor ??
        (isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant);
    final effectiveTextColor =
        textColor ?? (isSelected ? primaryColor : theme.colorScheme.onSurface);

    if (!isExpanded) {
      // Collapsed mode — chỉ hiện icon + tooltip
      return Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(0.08)
                  : Colors.transparent,
              border: isSelected
                  ? Border(left: BorderSide(color: primaryColor, width: 3))
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: effectiveIconColor, size: 24),
                if (badge != null)
                  Positioned(
                    right: 14,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge! > 9 ? '9+' : '$badge',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Expanded mode — icon + text + optional badge
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.08)
              : Colors.transparent,
          border: isSelected
              ? Border(left: BorderSide(color: primaryColor, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveIconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: effectiveTextColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
