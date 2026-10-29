// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_staff/features/wallet/models/staff_bank_account_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_bank_account_provider.dart';
import 'package:smartspace_staff/features/wallet/utils/uppercase_unaccent_formatter.dart';
import 'package:smartspace_staff/features/wallet/utils/vietnam_banks_helper.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class StaffBankAccountsScreen extends ConsumerStatefulWidget {
  const StaffBankAccountsScreen({super.key});

  @override
  ConsumerState<StaffBankAccountsScreen> createState() =>
      _StaffBankAccountsScreenState();
}

class _StaffBankAccountsScreenState
    extends ConsumerState<StaffBankAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bankAccountsState = ref.watch(staffBankAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bankAccountsManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.addBankAccount,
            onPressed: () => _showAddBankAccountModal(context, theme, l10n),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(staffBankAccountProvider.notifier).loadAccounts(),
        child: bankAccountsState.isLoading && bankAccountsState.accounts.isEmpty
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : bankAccountsState.accounts.isEmpty
                ? _buildEmptyState(theme, l10n)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bankAccountsState.accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = bankAccountsState.accounts[index];
                      return _buildBankAccountCard(
                        context,
                        theme,
                        isDark,
                        l10n,
                        item,
                      );
                    },
                  ),
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
                Icons.account_balance_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyBankAccounts,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.suggestSaveBankQuick,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  _showAddBankAccountModal(context, theme, l10n),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.addBankAccount),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    StaffBankAccountModel item,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bankName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.bankAccountNumber,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.bankAccountName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
              size: 22,
            ),
            tooltip: l10n.deleteBankAccount,
            onPressed: () => _confirmDeleteAccount(context, theme, l10n, item),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    StaffBankAccountModel item,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteBankAccount),
        content: Text(l10n.deleteBankAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(staffBankAccountProvider.notifier)
                  .deleteAccount(item.id);
              if (mounted) {
                if (success) {
                  Toast.show(ToastType.success, l10n.deleteSuccess);
                } else {
                  Toast.show(ToastType.error, l10n.genericError);
                }
              }
            },
            child: Text(l10n.confirmDelete),
          ),
        ],
      ),
    );
  }

  void _showAddBankAccountModal(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AddBankAccountBottomSheet(
        onSaved: (bankName, accNumber, accName, bankCode) async {
          final success = await ref
              .read(staffBankAccountProvider.notifier)
              .addAccount(
                bankName: bankName,
                bankAccountNumber: accNumber,
                bankAccountName: accName,
                bankCode: bankCode,
              );
          if (mounted) {
            if (success) {
              Toast.show(ToastType.success, l10n.saveSuccess);
            } else {
              Toast.show(ToastType.error, l10n.genericError);
            }
          }
        },
      ),
    );
  }
}

class _AddBankAccountBottomSheet extends StatefulWidget {
  final Future<void> Function(
    String bankName,
    String accNumber,
    String accName,
    String? bankCode,
  ) onSaved;

  const _AddBankAccountBottomSheet({required this.onSaved});

  @override
  State<_AddBankAccountBottomSheet> createState() =>
      _AddBankAccountBottomSheetState();
}

class _AddBankAccountBottomSheetState
    extends State<_AddBankAccountBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _accNameController = TextEditingController();
  String? _selectedBankCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accNumberController.dispose();
    _accNameController.dispose();
    super.dispose();
  }

  void _pickPopularBank(BankInfo bank) {
    setState(() {
      _selectedBankCode = bank.code;
      _bankNameController.text = bank.displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addBankAccount,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Gợi ý ngân hàng phổ biến (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: VietnamBanksHelper.popularBanks.take(8).map((b) {
                    final isSelected = _selectedBankCode == b.code;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(b.shortName),
                        backgroundColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : (isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.surfaceContainerLowest),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onPressed: () => _pickPopularBank(b),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Tên ngân hàng
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: l10n.bankName,
                  hintText: l10n.bankNameHint,
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.bankInfoIncomplete;
                  }
                  return null;
                },
                onChanged: (val) {
                  final detected = VietnamBanksHelper.findBank(val);
                  if (detected != null) {
                    _selectedBankCode = detected.code;
                  }
                },
              ),
              const SizedBox(height: 14),

              // 2. Số tài khoản
              TextFormField(
                controller: _accNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.bankAccountNumber,
                  hintText: l10n.bankAccountNumberHint,
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.bankInfoIncomplete;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Họ tên chủ tài khoản (In hoa không dấu)
              TextFormField(
                controller: _accNameController,
                inputFormatters: [UpperCaseUnaccentFormatter()],
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.bankAccountOwner,
                  hintText: l10n.bankAccountOwnerHint,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.bankInfoIncomplete;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isSubmitting = true);
                          final navigator = Navigator.of(context);
                          await widget.onSaved(
                            _bankNameController.text.trim(),
                            _accNumberController.text.trim(),
                            _accNameController.text.trim().toUpperCase(),
                            _selectedBankCode,
                          );
                          navigator.pop();
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: const TextStyle(
                            fontSize: 16,
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
}
