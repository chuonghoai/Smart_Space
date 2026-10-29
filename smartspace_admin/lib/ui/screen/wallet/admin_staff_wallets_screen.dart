import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/wallet_management/application/admin_wallet_list_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'widgets/staff_wallet_tile.dart';

class AdminStaffWalletsScreen extends StatefulWidget {
  const AdminStaffWalletsScreen({super.key});

  @override
  State<AdminStaffWalletsScreen> createState() => _AdminStaffWalletsScreenState();
}

class _AdminStaffWalletsScreenState extends State<AdminStaffWalletsScreen> {
  late final AdminWalletListController _controller;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AdminWalletListController();
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.manageStaffWallets),
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouterPath.home),
              ),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. BANNER THÔNG BÁO YÊU CẦU RÚT TIỀN
                _buildWithdrawalBanner(context, theme, colorScheme, isDark, l10n),
                const SizedBox(height: 18),

                // 2. SEARCH BAR
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchStaffHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _controller.loadData(search: '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (query) => _controller.loadData(search: query.trim()),
                ),
                const SizedBox(height: 16),

                // 3. DANH SÁCH VÍ NHÂN VIÊN
                if (_controller.isLoading && _controller.staffWallets.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_controller.staffWallets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 54,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noStaffWalletsFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._controller.staffWallets.map(
                    (staff) => StaffWalletTile(
                      staff: staff,
                      onTap: () {
                        context.push(
                          RouterPath.adminStaffWalletDetailWithId(staff.userId),
                          extra: staff.fullName,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWithdrawalBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final count = _controller.pendingWithdrawalCount;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: count > 0
              ? const Color(0xFFF57F17).withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: count > 0
          ? (isDark
              ? const Color(0xFFF57F17).withValues(alpha: 0.15)
              : const Color(0xFFFFF8E1))
          : (isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push(RouterPath.adminWithdrawalRequests);
          _controller.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: count > 0
                      ? const Color(0xFFF57F17).withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  count > 0 ? Icons.notification_important_rounded : Icons.pending_actions_rounded,
                  color: count > 0 ? const Color(0xFFE65100) : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pendingWithdrawalBanner(count),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0
                            ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFBF360C))
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.withdrawalRequests,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: count > 0
                    ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFBF360C))
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

