import 'package:flutter/foundation.dart';
import '../data/admin_wallet_repository.dart';
import '../models/staff_wallet_summary_model.dart';

class AdminWalletListController extends ChangeNotifier {
  final AdminWalletRepository _repository;

  AdminWalletListController({AdminWalletRepository? repository})
      : _repository = repository ?? adminWalletRepository;

  List<StaffWalletSummaryModel> _staffWallets = [];
  int _pendingWithdrawalCount = 0;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<StaffWalletSummaryModel> get staffWallets => _staffWallets;
  int get pendingWithdrawalCount => _pendingWithdrawalCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadData({String? search}) async {
    _isLoading = true;
    _error = null;
    if (search != null) {
      _searchQuery = search;
    }
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getStaffWallets(search: _searchQuery),
        _repository.getPendingWithdrawalCount(),
      ]);

      final walletsRes = results[0];
      final countRes = results[1];

      if (walletsRes.success && walletsRes.data != null) {
        _staffWallets = walletsRes.data as List<StaffWalletSummaryModel>;
      } else {
        _error = walletsRes.message;
      }

      if (countRes.success && countRes.data != null) {
        _pendingWithdrawalCount = countRes.data as int;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadData(search: _searchQuery);
  }
}

