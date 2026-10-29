import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_withdrawal_model.dart';
import 'package:smartspace_staff/features/wallet/repositories/staff_wallet_repo.dart';

class StaffWalletRepoApi implements StaffWalletRepo {
  @override
  Future<ApiResponse<StaffWalletModel>> getWallet() async {
    return await apiClient.get<StaffWalletModel>(
      '/staff/wallet',
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return StaffWalletModel.fromJson(json);
        }
        throw Exception('Invalid wallet format');
      },
    );
  }

  @override
  Future<ApiResponse<List<StaffWalletTransactionModel>>> getTransactions({
    int page = 0,
    int size = 20,
  }) async {
    return await apiClient.get<List<StaffWalletTransactionModel>>(
      '/staff/wallet/transactions?page=$page&size=$size',
      decoder: (json) {
        if (json is Map<String, dynamic> && json['content'] is List) {
          return (json['content'] as List)
              .map((e) => StaffWalletTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json
              .map((e) => StaffWalletTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<StaffWithdrawalModel>> createWithdrawal({
    required double amount,
    required String bankCode,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? note,
  }) async {
    final body = {
      'amount': amount,
      'bank_code': bankCode.trim(),
      'bank_name': bankName.trim(),
      'bank_account_number': bankAccountNumber.trim(),
      'bank_account_name': bankAccountName.trim().toUpperCase(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    return await apiClient.post<StaffWithdrawalModel>(
      '/staff/wallet/withdraw',
      data: body,
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return StaffWithdrawalModel.fromJson(json);
        }
        throw Exception('Invalid withdrawal response format');
      },
    );
  }

  @override
  Future<ApiResponse<List<StaffWithdrawalModel>>> getMyWithdrawals() async {
    return await apiClient.get<List<StaffWithdrawalModel>>(
      '/staff/wallet/withdrawals',
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => StaffWithdrawalModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }
}
