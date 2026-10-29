import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_wallet_repo.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_wallet_repo_api.dart';

class StaffWalletService {
  final StaffWalletRepo _repo;

  StaffWalletService([StaffWalletRepo? repo])
      : _repo = repo ?? StaffWalletRepoApi();

  Future<ApiResponse<StaffWalletModel>> getWallet() => _repo.getWallet();

  Future<ApiResponse<List<StaffWalletTransactionModel>>> getTransactions({
    int page = 0,
    int size = 20,
  }) =>
      _repo.getTransactions(page: page, size: size);

  Future<ApiResponse<StaffWithdrawalModel>> createWithdrawal({
    required double amount,
    required String bankCode,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? note,
  }) =>
      _repo.createWithdrawal(
        amount: amount,
        bankCode: bankCode,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        note: note,
      );

  Future<ApiResponse<List<StaffWithdrawalModel>>> getMyWithdrawals() =>
      _repo.getMyWithdrawals();

  Future<ApiResponse<StaffWithdrawalModel>> cancelWithdrawal(String id) =>
      _repo.cancelWithdrawal(id);
}

final staffWalletService = StaffWalletService();
