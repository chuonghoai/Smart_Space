import 'package:flutter/material.dart';
import '../models/wallet_config_model.dart';
import '../data/wallet_config_repository.dart';

class WalletConfigController extends ChangeNotifier {
  final WalletConfigRepository _repository;

  WalletConfigController({WalletConfigRepository? repository})
      : _repository = repository ?? walletConfigRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  WalletConfigModel? _config;
  WalletConfigModel? get config => _config;

  Future<void> loadConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getWalletConfig();
      if (response.success && response.data != null) {
        _config = response.data;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConfig(WalletConfigModel newConfig) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.updateWalletConfig(newConfig);
      if (response.success && response.data != null) {
        _config = response.data;
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}

