import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';

abstract class StaffWalletRepo {
  Future<ApiResponse<StaffWalletModel>> getWallet();
  Future<ApiResponse<List<StaffWalletTransactionModel>>> getTransactions({
    int page = 0,
    int size = 20,
  });
  Future<ApiResponse<StaffWithdrawalModel>> createWithdrawal({
    required double amount,
    required String bankCode,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? note,
  });
  Future<ApiResponse<List<StaffWithdrawalModel>>> getMyWithdrawals();
}
