import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_admin/features/wallet_config/application/wallet_config_controller.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  late final WalletConfigController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WalletConfigController();
    _controller.loadConfig();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        title: Text(l10n.systemConfig),
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
      child: RefreshIndicator(
        onRefresh: () => _controller.loadConfig(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          children: [
            // Header Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.systemConfig,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.walletConfigDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Item 1: Cấu hình hoa hồng
            _buildConfigOptionCard(
              context: context,
              theme: theme,
              colorScheme: colorScheme,
              icon: Icons.monetization_on_outlined,
              iconColor: const Color(0xFF2E7D32),
              title: l10n.commissionConfig,
              subtitle: l10n.commissionConfigDescription,
              onTap: () async {
                await context.push(RouterPath.commissionConfig);
                _controller.loadConfig();
              },
            ),
            const SizedBox(height: 14),

            // Item 2: Cấu hình tỷ lệ trừ hoa hồng khi xử lý lại
            _buildConfigOptionCard(
              context: context,
              theme: theme,
              colorScheme: colorScheme,
              icon: Icons.percent_outlined,
              iconColor: const Color(0xFFE65100),
              title: l10n.penaltyRateConfig,
              subtitle: l10n.penaltyRateConfigDescription,
              onTap: () async {
                await context.push(RouterPath.penaltyRateConfig);
                _controller.loadConfig();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOptionCard({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

