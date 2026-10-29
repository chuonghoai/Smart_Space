// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_wallet_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class StaffWalletScreen extends ConsumerStatefulWidget {
  const StaffWalletScreen({super.key});

  @override
  ConsumerState<StaffWalletScreen> createState() => _StaffWalletScreenState();
}

class _StaffWalletScreenState extends ConsumerState<StaffWalletScreen> {
  bool _obscureBalance = false;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final walletState = ref.watch(staffWalletProvider);
    final transactionsState = ref.watch(staffTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffWallet),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouterPath.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () async {
              await Future.wait([
                ref.read(staffWalletProvider.notifier).refresh(),
                ref.read(staffTransactionsProvider.notifier).refresh(),
              ]);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(staffWalletProvider.notifier).refresh(),
            ref.read(staffTransactionsProvider.notifier).refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(context, theme, isDark, l10n, walletState),
              const SizedBox(height: 20),

              // Action Buttons Row (Rút tiền & Lịch sử giao dịch)
              _buildActionButtons(context, theme, isDark, l10n),
              const SizedBox(height: 28),

              // Recent Transactions Header
              Text(
                l10n.recentTransactions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Transactions List
              _buildRecentTransactionsList(
                context,
                theme,
                isDark,
                l10n,
                transactionsState,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    StaffWalletState walletState,
  ) {
    final balance = walletState.wallet?.balance ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.walletBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _obscureBalance
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscureBalance = !_obscureBalance;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: walletState.isLoading && walletState.wallet == null
                    ? const SizedBox(
                        height: 40,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Text(
                        _obscureBalance ? '****** đ' : _formatCurrency(balance),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.push(RouterPath.staffWithdrawal),
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                label: Text(
                  l10n.withdrawMoney,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        // Nút Lịch sử rút tiền
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(RouterPath.staffWithdrawalHistory);
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 20),
            label: Text(l10n.withdrawalHistory),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Nút Lịch sử giao dịch
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(RouterPath.staffWalletTransactions);
            },
            icon: const Icon(Icons.history_rounded, size: 20),
            label: Text(l10n.transactionHistory),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    StaffTransactionsState transactionsState,
  ) {
    if (transactionsState.isLoading && transactionsState.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (transactionsState.transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noTransactions,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Top 5 recent items
    final displayItems = transactionsState.transactions.take(5).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final t = displayItems[index];
            return _buildTransactionTile(context, theme, isDark, l10n, t);
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              context.push(RouterPath.staffWalletTransactions);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.viewAll,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    StaffWalletTransactionModel t,
  ) {
    final isIncome = t.isIncome;
    final successColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final errorColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
    final color = isIncome ? successColor : errorColor;

    return InkWell(
      onTap: t.reportId != null
          ? () {
              context.push(RouterPath.reportDetail.replaceAll(':id', t.reportId!));
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (t.reportTitle != null && t.reportTitle!.isNotEmpty) ...[
                    Text(
                      t.reportTitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${_formatCurrency(t.amount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(t.balanceAfter),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

