import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_bank_account_model.dart';

abstract class StaffBankAccountRepo {
  Future<ApiResponse<List<StaffBankAccountModel>>> getBankAccounts();
  Future<ApiResponse<StaffBankAccountModel>> addBankAccount({
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? bankCode,
  });
  Future<ApiResponse<void>> deleteBankAccount(String id);
}

