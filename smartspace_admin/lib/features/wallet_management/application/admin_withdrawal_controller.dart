import 'package:flutter/foundation.dart';
import '../data/admin_wallet_repository.dart';
import '../models/withdrawal_request_model.dart';

class AdminWithdrawalController extends ChangeNotifier {
  final AdminWalletRepository _repository;

  AdminWithdrawalController({AdminWalletRepository? repository})
      : _repository = repository ?? adminWalletRepository;

  List<WithdrawalRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'ALL'; // ALL, PENDING, APPROVED, REJECTED

  List<WithdrawalRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  Future<void> loadRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _repository.getWithdrawals(status: _currentFilter);
      if (res.success && res.data != null) {
        _requests = res.data!;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    loadRequests();
  }

  Future<bool> processRequest(String id, String status, {String? adminNote}) async {
    try {
      final res = await _repository.processWithdrawal(
        id: id,
        status: status,
        adminNote: adminNote,
      );

      if (res.success) {
        await loadRequests();
        return true;
      } else {
        _error = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    await loadRequests();
  }
}

