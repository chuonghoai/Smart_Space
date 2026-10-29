import 'package:flutter/foundation.dart';
import '../data/admin_wallet_repository.dart';
import '../models/staff_wallet_summary_model.dart';
import '../models/staff_transaction_item_model.dart';

class AdminStaffWalletDetailController extends ChangeNotifier {
  final AdminWalletRepository _repository;
  final String staffId;

  AdminStaffWalletDetailController({
    required this.staffId,
    AdminWalletRepository? repository,
  }) : _repository = repository ?? adminWalletRepository;

  StaffWalletSummaryModel? _wallet;
  List<StaffTransactionItemModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  StaffWalletSummaryModel? get wallet => _wallet;
  List<StaffTransactionItemModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDetails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getStaffWalletDetail(staffId),
        _repository.getStaffTransactions(staffId: staffId),
      ]);

      final walletRes = results[0];
      final transRes = results[1];

      if (walletRes.success && walletRes.data != null) {
        _wallet = walletRes.data as StaffWalletSummaryModel;
      } else {
        _error = walletRes.message;
      }

      if (transRes.success && transRes.data != null) {
        _transactions = transRes.data as List<StaffTransactionItemModel>;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDetails();
  }
}

