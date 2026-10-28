import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';

abstract class StaffWalletRepo {
  Future<ApiResponse<StaffWalletModel>> getWallet();
  Future<ApiResponse<List<StaffWalletTransactionModel>>> getTransactions({
    int page = 0,
    int size = 20,
  });
}

