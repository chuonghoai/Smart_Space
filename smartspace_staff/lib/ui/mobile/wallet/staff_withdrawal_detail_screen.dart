// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_withdrawal_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class StaffWithdrawalDetailScreen extends ConsumerStatefulWidget {
  final String withdrawalId;
  final StaffWithdrawalModel? initialModel;

  const StaffWithdrawalDetailScreen({
    super.key,
    required this.withdrawalId,
    this.initialModel,
  });

  @override
  ConsumerState<StaffWithdrawalDetailScreen> createState() =>
      _StaffWithdrawalDetailScreenState();
}

class _StaffWithdrawalDetailScreenState
    extends ConsumerState<StaffWithdrawalDetailScreen> {
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialModel == null) {
        ref.read(staffWithdrawalProvider.notifier).loadWithdrawals();
      }
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final withdrawalState = ref.watch(staffWithdrawalProvider);
    final item = withdrawalState.withdrawals.cast<StaffWithdrawalModel?>().firstWhere(
          (w) => w?.id == widget.withdrawalId,
          orElse: () => widget.initialModel,
        );

    if (item == null) {
      if (withdrawalState.isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.withdrawalDetail),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.withdrawalDetail),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.genericError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(staffWithdrawalProvider.notifier).loadWithdrawals();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.withdrawalDetail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount & Status Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatCurrency(item.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice for PENDING / CANCELLED requests
            if (item.isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFFB74D).withOpacity(0.12)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFB74D).withOpacity(0.4)
                        : const Color(0xFFFFB74D),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      color: isDark
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFE65100),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.heldWithdrawalNoticeTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.heldWithdrawalNoticeDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (item.isCancelled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFEF5350).withOpacity(0.10)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFEF5350).withOpacity(0.35)
                        : const Color(0xFFEF9A9A),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: isDark
                          ? const Color(0xFFEF5350)
                          : const Color(0xFFC62828),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.statusCancelled,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.cancelledNoticeDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bank Account Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bankAccount,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    context,
                    theme,
                    l10n.bankName,
                    item.bankName,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    theme,
                    l10n.bankAccountNumber,
                    item.bankAccountNumber,
                    isHighlight: true,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    theme,
                    l10n.bankAccountOwner,
                    item.bankAccountName,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    theme,
                    l10n.createdDate,
                    _formatDateTime(item.createdAt),
                  ),
                  if (item.processedAt != null) ...[
                    const Divider(height: 20),
                    _buildDetailRow(
                      context,
                      theme,
                      l10n.filterApproved,
                      _formatDateTime(item.processedAt),
                    ),
                  ],
                ],
              ),
            ),

            // Additional Info: Cancellation reason (displayed for cancelled/rejected requests)
            if (item.isRejected || item.isCancelled) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFEF5350).withOpacity(0.08)
                      : const Color(0xFFC62828).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.additionalInfo,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.cancellationReason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (item.adminNote != null &&
                              item.adminNote!.trim().isNotEmpty)
                          ? item.adminNote!
                          : l10n.noCancellationReasonProvided,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF2E7D32))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.refundedNoticeDesc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: item.canCancel
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : () => _handleCancel(item, l10n),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: _isCancelling
                            ? theme.colorScheme.error.withOpacity(0.4)
                            : theme.colorScheme.error,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isCancelling
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.error,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined, size: 20),
                    label: Text(
                      l10n.cancelWithdrawalRequest,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCancel(
    StaffWithdrawalModel item,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        final isDialogDark = dialogTheme.brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDialogDark
              ? dialogTheme.colorScheme.surfaceContainerHighest
              : dialogTheme.colorScheme.surface,
          title: Text(
            l10n.confirmCancelWithdrawalTitle,
            style: dialogTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.confirmCancelWithdrawalContent,
            style: dialogTheme.textTheme.bodyMedium?.copyWith(
              color: dialogTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: dialogTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: dialogTheme.colorScheme.error,
                foregroundColor: dialogTheme.colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                l10n.confirmCancel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final res = await ref.read(staffWithdrawalProvider.notifier).cancelWithdrawal(item.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cancelWithdrawalSuccess),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : l10n.genericError),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
