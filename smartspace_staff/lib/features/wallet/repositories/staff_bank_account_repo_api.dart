import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_bank_account_model.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_bank_account_repo.dart';

class StaffBankAccountRepoApi implements StaffBankAccountRepo {
  @override
  Future<ApiResponse<List<StaffBankAccountModel>>> getBankAccounts() async {
    return await apiClient.get<List<StaffBankAccountModel>>(
      '/staff/bank-accounts',
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => StaffBankAccountModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<StaffBankAccountModel>> addBankAccount({
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? bankCode,
  }) async {
    final body = {
      'bank_name': bankName.trim(),
      'bank_account_number': bankAccountNumber.trim(),
      'bank_account_name': bankAccountName.trim().toUpperCase(),
      if (bankCode != null && bankCode.trim().isNotEmpty)
        'bank_code': bankCode.trim(),
    };

    return await apiClient.post<StaffBankAccountModel>(
      '/staff/bank-accounts',
      data: body,
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return StaffBankAccountModel.fromJson(json);
        }
        throw Exception('Invalid bank account format');
      },
    );
  }

  @override
  Future<ApiResponse<void>> deleteBankAccount(String id) async {
    return await apiClient.delete<void>('/staff/bank-accounts/$id');
  }
}

