import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
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
}

final staffWalletService = StaffWalletService();

