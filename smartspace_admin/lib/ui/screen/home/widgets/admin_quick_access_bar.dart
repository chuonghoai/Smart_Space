import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';

class AdminQuickAccessBar extends StatefulWidget {
  final bool isPanelMode;

  const AdminQuickAccessBar({super.key, this.isPanelMode = false});

  @override
  State<AdminQuickAccessBar> createState() => _AdminQuickAccessBarState();
}

class _AdminQuickAccessBarState extends State<AdminQuickAccessBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset - 240)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + 240)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

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
        title: l10n.withdrawalRequests,
        icon: Icons.payments_outlined,
        onTap: () => context.push(RouterPath.adminWithdrawalRequests),
      ),
      _QuickAccessItemData(
        title: l10n.manageStaffWallets,
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => context.push(RouterPath.adminStaffWallets),
      ),
      _QuickAccessItemData(
        title: l10n.manageUsers,
        icon: Icons.people_outline,
        onTap: () => context.push(RouterPath.userManagement),
      ),
      _QuickAccessItemData(
        title: l10n.manageNews,
        icon: Icons.newspaper_outlined,
        onTap: () => context.push(RouterPath.newsManagement),
      ),
      _QuickAccessItemData(
        title: l10n.systemConfig,
        icon: Icons.tune_outlined,
        onTap: () => context.push(RouterPath.systemConfig),
      ),
    ];

    if (widget.isPanelMode) {
      return _buildPanelMode(context, items, theme, colorScheme, isDark, l10n);
    }

    return _buildScrollableMode(context, items, theme, colorScheme, isDark, l10n);
  }

  Widget _buildPanelMode(
    BuildContext context,
    List<_QuickAccessItemData> items,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
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
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 60,
            ),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final item = items[idx];
              return Material(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: item.onTap,
                  hoverColor: colorScheme.primary.withValues(alpha: 0.08),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.icon,
                            color: colorScheme.primary,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableMode(
    BuildContext context,
    List<_QuickAccessItemData> items,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations l10n,
  ) {
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
            const Spacer(),
            // Nút cuộn tiện ích trên màn hình web/desktop
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.scrollLeft,
              onPressed: _scrollLeft,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.scrollRight,
              onPressed: _scrollRight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Thanh danh sách card trượt ngang đồng nhất như mobile, kèm scrollbar bên dưới
        ScrollConfiguration(
          behavior: const _WebTouchAndMouseScrollBehavior(),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: kIsWeb,
            trackVisibility: kIsWeb,
            thickness: 6,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: items.map((item) {
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12.0),
                    child: _buildItemCard(
                      context,
                      item,
                      theme,
                      colorScheme,
                      isDark,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
          height: 112,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary
                      .withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
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

class _WebTouchAndMouseScrollBehavior extends MaterialScrollBehavior {
  const _WebTouchAndMouseScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
