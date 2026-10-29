import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import '../models/staff_wallet_summary_model.dart';
import '../models/staff_transaction_item_model.dart';
import '../models/withdrawal_request_model.dart';

class AdminWalletRepository {
  Future<ApiResponse<List<StaffWalletSummaryModel>>> getStaffWallets({
    int page = 1,
    int size = 30,
    String? search,
  }) async {
    return apiClient.get(
      '/admin/wallet/staffs',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      decoder: (json) {
        if (json is Map<String, dynamic> && json['content'] is List) {
          return (json['content'] as List)
              .map((item) => StaffWalletSummaryModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <StaffWalletSummaryModel>[];
      },
    );
  }

  Future<ApiResponse<StaffWalletSummaryModel>> getStaffWalletDetail(String staffId) async {
    return apiClient.get(
      '/admin/wallet/staffs/$staffId',
      decoder: (json) => StaffWalletSummaryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<StaffTransactionItemModel>>> getStaffTransactions({
    required String staffId,
    int page = 0,
    int size = 30,
  }) async {
    return apiClient.get(
      '/admin/wallet/staffs/$staffId/transactions',
      queryParameters: {
        'page': page,
        'size': size,
      },
      decoder: (json) {
        if (json is Map<String, dynamic> && json['content'] is List) {
          return (json['content'] as List)
              .map((item) => StaffTransactionItemModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <StaffTransactionItemModel>[];
      },
    );
  }

  Future<ApiResponse<int>> getPendingWithdrawalCount() async {
    return apiClient.get(
      '/admin/wallet/withdrawals/pending-count',
      decoder: (json) => (json as num?)?.toInt() ?? 0,
    );
  }

  Future<ApiResponse<List<WithdrawalRequestModel>>> getWithdrawals({
    String? status,
    int page = 1,
    int size = 30,
  }) async {
    return apiClient.get(
      '/admin/wallet/withdrawals',
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null && status != 'ALL') 'status': status,
      },
      decoder: (json) {
        if (json is Map<String, dynamic> && json['content'] is List) {
          return (json['content'] as List)
              .map((item) => WithdrawalRequestModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <WithdrawalRequestModel>[];
      },
    );
  }

  Future<ApiResponse<WithdrawalRequestModel>> processWithdrawal({
    required String id,
    required String status,
    String? adminNote,
  }) async {
    return apiClient.put(
      '/admin/wallet/withdrawals/$id/process',
      data: {
        'status': status,
        if (adminNote != null && adminNote.isNotEmpty) 'admin_note': adminNote,
      },
      decoder: (json) => WithdrawalRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }
}

final adminWalletRepository = AdminWalletRepository();

