import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';

class AdminQuickAccessBar extends StatelessWidget {
  const AdminQuickAccessBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _QuickAccessItemData(
        title: l10n.manageReports,
        icon: Icons.report_outlined,
        onTap: () => context.push(RouterPath.reportDashboard),
      ),
      _QuickAccessItemData(
        title: l10n.spaceMap,
        icon: Icons.map_outlined,
        onTap: () => context.push(RouterPath.spaceMap),
      ),
      _QuickAccessItemData(
        title: l10n.manageStaffs,
        icon: Icons.badge_outlined,
        onTap: () => context.push(RouterPath.staffManagement),
      ),
      _QuickAccessItemData(
        title: l10n.manageUsers,
        icon: Icons.people_outline,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.manageUsers),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
      _QuickAccessItemData(
        title: l10n.manageNews,
        icon: Icons.newspaper_outlined,
        onTap: () => context.push(RouterPath.newsManagement),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.quickAccess,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive: If wide enough (e.g. tablet/desktop web > 600px), show in 1 row of 5 columns.
            // On mobile screen, horizontal scrollable row with smooth cards.
            if (constraints.maxWidth >= 600) {
              return Row(
                children: items.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildItemCard(context, item, theme, colorScheme, isDark),
                    ),
                  );
                }).toList(),
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: items.map((item) {
                    return Container(
                      width: 104,
                      margin: const EdgeInsets.only(right: 10.0),
                      child: _buildItemCard(context, item, theme, colorScheme, isDark),
                    );
                  }).toList(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    _QuickAccessItemData item,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Material(
      color: isDark ? colorScheme.surface : theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
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
}

class _QuickAccessItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _QuickAccessItemData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
