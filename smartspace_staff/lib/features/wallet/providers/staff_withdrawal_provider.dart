import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';
import 'package:smartspace_staff/features/wallet/providers/staff_wallet_provider.dart';
import 'package:smartspace_staff/features/wallet/services/staff_wallet_service.dart';

enum WithdrawalFilter { all, approved, rejected }

class StaffWithdrawalState {
  final bool isLoading;
  final List<StaffWithdrawalModel> withdrawals;
  final WithdrawalFilter filter;
  final String? error;

  StaffWithdrawalState({
    this.isLoading = false,
    this.withdrawals = const [],
    this.filter = WithdrawalFilter.all,
    this.error,
  });

  List<StaffWithdrawalModel> get filteredWithdrawals {
    switch (filter) {
      case WithdrawalFilter.approved:
        return withdrawals.where((w) => w.isApproved).toList();
      case WithdrawalFilter.rejected:
        return withdrawals.where((w) => w.isRejected).toList();
      case WithdrawalFilter.all:
        return withdrawals;
    }
  }

  StaffWithdrawalState copyWith({
    bool? isLoading,
    List<StaffWithdrawalModel>? withdrawals,
    WithdrawalFilter? filter,
    String? error,
  }) {
    return StaffWithdrawalState(
      isLoading: isLoading ?? this.isLoading,
      withdrawals: withdrawals ?? this.withdrawals,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}

class StaffWithdrawalNotifier extends StateNotifier<StaffWithdrawalState> {
  final Ref _ref;

  StaffWithdrawalNotifier(this._ref) : super(StaffWithdrawalState()) {
    loadWithdrawals();
  }

  void setFilter(WithdrawalFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> loadWithdrawals({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await staffWalletService.getMyWithdrawals();
      if (res.success && res.data != null) {
        state = state.copyWith(
          withdrawals: res.data!,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.message,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createWithdrawal({
    required double amount,
    required String bankCode,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? note,
  }) async {
    try {
      final res = await staffWalletService.createWithdrawal(
        amount: amount,
        bankCode: bankCode,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        note: note,
      );
      if (res.success) {
        state = state.copyWith(filter: WithdrawalFilter.all);
        await Future.wait([
          loadWithdrawals(silent: true),
          _ref.read(staffWalletProvider.notifier).refresh(),
        ]);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final staffWithdrawalProvider =
    StateNotifierProvider<StaffWithdrawalNotifier, StaffWithdrawalState>((ref) {
  return StaffWithdrawalNotifier(ref);
});
