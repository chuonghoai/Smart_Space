import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/wallet/models/staff_bank_account_model.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_bank_account_repo.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_bank_account_repo_api.dart';

class StaffBankAccountState {
  final bool isLoading;
  final List<StaffBankAccountModel> accounts;
  final String? error;

  StaffBankAccountState({
    this.isLoading = false,
    this.accounts = const [],
    this.error,
  });

  StaffBankAccountState copyWith({
    bool? isLoading,
    List<StaffBankAccountModel>? accounts,
    String? error,
  }) {
    return StaffBankAccountState(
      isLoading: isLoading ?? this.isLoading,
      accounts: accounts ?? this.accounts,
      error: error,
    );
  }
}

class StaffBankAccountNotifier extends StateNotifier<StaffBankAccountState> {
  final StaffBankAccountRepo _repo;

  StaffBankAccountNotifier([StaffBankAccountRepo? repo])
      : _repo = repo ?? StaffBankAccountRepoApi(),
        super(StaffBankAccountState()) {
    loadAccounts();
  }

  Future<void> loadAccounts({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await _repo.getBankAccounts();
      if (res.success && res.data != null) {
        state = state.copyWith(
          accounts: res.data!,
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

  Future<bool> addAccount({
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? bankCode,
  }) async {
    try {
      final res = await _repo.addBankAccount(
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        bankCode: bankCode,
      );
      if (res.success) {
        await loadAccounts(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(String id) async {
    try {
      final res = await _repo.deleteBankAccount(id);
      if (res.success) {
        state = state.copyWith(
          accounts: state.accounts.where((a) => a.id != id).toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final staffBankAccountProvider =
    StateNotifierProvider<StaffBankAccountNotifier, StaffBankAccountState>((ref) {
  return StaffBankAccountNotifier();
});

