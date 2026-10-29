// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_withdrawal_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class StaffWithdrawalHistoryScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const StaffWithdrawalHistoryScreen({super.key, this.initialFilter});

  @override
  ConsumerState<StaffWithdrawalHistoryScreen> createState() =>
      _StaffWithdrawalHistoryScreenState();
}

class _StaffWithdrawalHistoryScreenState
    extends ConsumerState<StaffWithdrawalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialFilter != null) {
        final f = widget.initialFilter!.toLowerCase();
        if (f == 'approved') {
          ref.read(staffWithdrawalProvider.notifier).setFilter(WithdrawalFilter.approved);
        } else if (f == 'rejected') {
          ref.read(staffWithdrawalProvider.notifier).setFilter(WithdrawalFilter.rejected);
        } else {
          ref.read(staffWithdrawalProvider.notifier).setFilter(WithdrawalFilter.all);
        }
      }
    });
  }
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final withdrawalState = ref.watch(staffWithdrawalProvider);
    final notifier = ref.read(staffWithdrawalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.withdrawalHistory),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (Tất cả, Đã duyệt, Đã hủy)
          _buildFilterBar(theme, isDark, l10n, withdrawalState.filter, notifier),

          // Requests List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadWithdrawals(),
              child: withdrawalState.isLoading &&
                      withdrawalState.withdrawals.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : withdrawalState.filteredWithdrawals.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              withdrawalState.filteredWithdrawals.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item =
                                withdrawalState.filteredWithdrawals[index];
                            return _buildWithdrawalCard(
                              context,
                              theme,
                              isDark,
                              l10n,
                              item,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    WithdrawalFilter currentFilter,
    StaffWithdrawalNotifier notifier,
  ) {
    final filters = [
      {'filter': WithdrawalFilter.all, 'label': l10n.filterAll},
      {'filter': WithdrawalFilter.approved, 'label': l10n.filterApproved},
      {'filter': WithdrawalFilter.rejected, 'label': l10n.filterRejected},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: filters.map((f) {
          final filterType = f['filter'] as WithdrawalFilter;
          final label = f['label'] as String;
          final isSelected = currentFilter == filterType;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(label),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 13,
              ),
              backgroundColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerLowest,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              onSelected: (_) => notifier.setFilter(filterType),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyWithdrawalHistory,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    StaffWithdrawalModel item,
  ) {
    Color statusColor;
    Color statusBgColor;
    String statusLabel;
    IconData statusIcon;

    if (item.isApproved) {
      statusColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
      statusBgColor = statusColor.withOpacity(0.12);
      statusLabel = l10n.statusApproved;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (item.isRejected) {
      statusColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
      statusBgColor = statusColor.withOpacity(0.12);
      statusLabel = l10n.statusRejected;
      statusIcon = Icons.cancel_outlined;
    } else if (item.isCancelled) {
      statusColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
      statusBgColor = statusColor.withOpacity(0.12);
      statusLabel = l10n.statusCancelled;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
      statusBgColor = statusColor.withOpacity(0.12);
      statusLabel = l10n.statusPending;
      statusIcon = Icons.access_time_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push(
            RouterPath.staffWithdrawalDetailWithId(item.id),
            extra: item,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Amount & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(item.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bank info
              Row(
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.bankName} (${item.bankAccountNumber})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Account Owner & Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.bankAccountName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              // Hint to tap if rejected or cancelled
              if (item.isRejected || item.isCancelled) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.cancellationReason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
