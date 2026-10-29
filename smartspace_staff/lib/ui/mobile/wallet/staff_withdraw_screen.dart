// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:smartspace_staff/features/wallet/models/staff_bank_account_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_bank_account_provider.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_wallet_provider.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_withdrawal_provider.dart';
import 'package:smartspace_staff/features/wallet/utils/currency_input_formatter.dart';
import 'package:smartspace_staff/features/wallet/utils/uppercase_unaccent_formatter.dart';
import 'package:smartspace_staff/features/wallet/utils/vietnam_banks_helper.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';

class StaffWithdrawScreen extends ConsumerStatefulWidget {
  const StaffWithdrawScreen({super.key});

  @override
  ConsumerState<StaffWithdrawScreen> createState() =>
      _StaffWithdrawScreenState();
}

class _StaffWithdrawScreenState extends ConsumerState<StaffWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _accNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedBankCode;
  StaffBankAccountModel? _selectedSavedAccount;
  bool _isSubmitting = false;

  final _bankNameFocus = FocusNode();
  final _accNumberFocus = FocusNode();
  final _accNameFocus = FocusNode();
  final _amountFocus = FocusNode();

  @override
  void dispose() {
    _bankNameController.dispose();
    _accNumberController.dispose();
    _accNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _bankNameFocus.dispose();
    _accNumberFocus.dispose();
    _accNameFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onSelectSavedAccount(StaffBankAccountModel account) {
    setState(() {
      _selectedSavedAccount = account;
      _bankNameController.text = account.bankName;
      _accNumberController.text = account.bankAccountNumber;
      _accNameController.text = account.bankAccountName;
      _selectedBankCode = account.bankCode;
    });
  }

  void _pickPopularBank(BankInfo bank) {
    setState(() {
      _selectedBankCode = bank.code;
      _bankNameController.text = bank.displayName;
      if (_selectedSavedAccount != null &&
          _selectedSavedAccount!.bankName != bank.displayName) {
        _selectedSavedAccount = null;
      }
    });
  }

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
    final bankAccountsState = ref.watch(staffBankAccountProvider);
    final currentBalance = walletState.wallet?.balance ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.withdrawMoney),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Card
              _buildBalanceSummary(theme, isDark, l10n, currentBalance),
              const SizedBox(height: 16),

              // Saved Bank Accounts Dropdown / Quick Picker
              _buildSavedBankSection(
                context,
                theme,
                isDark,
                l10n,
                bankAccountsState.accounts,
              ),
              const SizedBox(height: 20),

              // Form Header
              Text(
                l10n.bankAccount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Gợi ý chọn nhanh ngân hàng phổ biến (Chips)
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
              const SizedBox(height: 14),

              // 1. Tên ngân hàng
              TextFormField(
                controller: _bankNameController,
                focusNode: _bankNameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_accNumberFocus),
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
                  if (_selectedSavedAccount != null &&
                      _selectedSavedAccount!.bankName != val) {
                    setState(() => _selectedSavedAccount = null);
                  }
                },
              ),
              const SizedBox(height: 14),

              // 2. Số tài khoản
              TextFormField(
                controller: _accNumberController,
                focusNode: _accNumberFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_accNameFocus),
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
                onChanged: (val) {
                  if (_selectedSavedAccount != null &&
                      _selectedSavedAccount!.bankAccountNumber != val) {
                    setState(() => _selectedSavedAccount = null);
                  }
                },
              ),
              const SizedBox(height: 14),

              // 3. Họ tên chủ tài khoản (In hoa không dấu)
              TextFormField(
                controller: _accNameController,
                focusNode: _accNameFocus,
                textInputAction: TextInputAction.next,
                inputFormatters: [UpperCaseUnaccentFormatter()],
                textCapitalization: TextCapitalization.characters,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_amountFocus),
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
              const SizedBox(height: 14),

              // 4. Số tiền muốn rút (Currency input format)
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                decoration: InputDecoration(
                  labelText: l10n.withdrawalAmount,
                  hintText: l10n.withdrawalAmountHint,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: 'đ',
                  suffixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.withdrawalAmountHint;
                  }
                  final amount = CurrencyInputFormatter.parseAmount(val);
                  if (amount < 10000) {
                    return l10n.minWithdrawalAmountError;
                  }
                  if (amount > currentBalance) {
                    return l10n.amountExceedsBalance;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút Gửi yêu cầu rút tiền
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : () => _handleSubmit(l10n),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                  label: Text(
                    l10n.submitWithdrawalRequest,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildBalanceSummary(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    double balance,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.walletBalance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(balance),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedBankSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    List<StaffBankAccountModel> savedAccounts,
  ) {
    if (savedAccounts.isEmpty) {
      // Suggestion prompt card - clickable to navigate to bank accounts management
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await context.push(RouterPath.staffBankAccounts);
            ref.read(staffBankAccountProvider.notifier).loadAccounts();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.suggestSaveBankQuick,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Dropdown to pick a saved account with bottom option to add new bank account
    final dropdownItems = <DropdownMenuItem<StaffBankAccountModel>>[
      ...savedAccounts.map((acc) {
        return DropdownMenuItem<StaffBankAccountModel>(
          value: acc,
          child: Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${acc.bankName} - ${acc.bankAccountNumber}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      DropdownMenuItem<StaffBankAccountModel>(
        value: StaffBankAccountModel(
          id: '__add_new__',
          bankName: '',
          bankAccountNumber: '',
          bankAccountName: '',
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.addNewBankAccount,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StaffBankAccountModel>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.selectSavedBankAccount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          value: savedAccounts
              .where((a) => a.id == _selectedSavedAccount?.id)
              .firstOrNull,
          items: dropdownItems,
          onChanged: (acc) async {
            if (acc?.id == '__add_new__') {
              await context.push(RouterPath.staffBankAccounts);
              ref.read(staffBankAccountProvider.notifier).loadAccounts();
              return;
            }
            if (acc != null) {
              _onSelectSavedAccount(acc);
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final bankName = _bankNameController.text.trim();
    final accNumber = _accNumberController.text.trim();
    final accName = _accNameController.text.trim().toUpperCase();
    final amount = CurrencyInputFormatter.parseAmount(_amountController.text);
    final bankCode = _selectedBankCode ??
        VietnamBanksHelper.findBank(bankName)?.code ??
        bankName;

    final savedAccounts = ref.read(staffBankAccountProvider).accounts;
    final isAlreadySaved = savedAccounts.any((a) =>
        a.bankAccountNumber.trim() == accNumber);

    if (!isAlreadySaved) {
      // Show confirmation dialog to save bank account
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.saveBankModalTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
                tooltip: l10n.cancel,
                onPressed: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
          content: Text(l10n.confirmSaveBankPrompt),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.doNotSave),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (shouldSave == null) {
        // Người dùng bấm nút "X" hoặc đóng modal -> Hủy thao tác submit API
        return;
      }

      if (shouldSave == true) {
        await ref.read(staffBankAccountProvider.notifier).addAccount(
              bankName: bankName,
              bankAccountNumber: accNumber,
              bankAccountName: accName,
              bankCode: bankCode,
            );
      }
    }

    // Now execute withdrawal
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(staffWithdrawalProvider.notifier)
        .createWithdrawal(
          amount: amount,
          bankCode: bankCode,
          bankName: bankName,
          bankAccountNumber: accNumber,
          bankAccountName: accName,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Toast.show(ToastType.success, l10n.withdrawalRequestSuccess);
        ref.read(staffWalletProvider.notifier).refresh();
        ref.read(staffTransactionsProvider.notifier).refresh();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouterPath.staffWallet);
        }
      } else {
        Toast.show(ToastType.error, l10n.genericError);
      }
    }
  }
}

