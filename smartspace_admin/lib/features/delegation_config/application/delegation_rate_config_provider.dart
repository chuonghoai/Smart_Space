import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/delegation_rate_config_repository.dart';
import '../models/delegation_rate_config_model.dart';

/// Cấu hình tỷ lệ bonus nhờ làm giùm. Lưu lỗi thì giữ nguyên cấu hình đang hiển thị.
class DelegationRateConfigNotifier extends AutoDisposeAsyncNotifier<DelegationRateConfigModel> {
  final DelegationRateConfigRepository _repository;

  DelegationRateConfigNotifier({DelegationRateConfigRepository? repository})
      : _repository = repository ?? delegationRateConfigRepository;

  @override
  Future<DelegationRateConfigModel> build() async {
    final response = await _repository.getConfig();
    final data = response.data;
    if (!response.success || data == null) throw Exception(response.message);
    return data;
  }

  /// Trả về null khi lưu thành công, ngược lại là thông báo lỗi từ backend.
  Future<String?> save({
    required double low,
    required double medium,
    required double high,
    required double critical,
  }) async {
    try {
      final response = await _repository.updateRates(low: low, medium: medium, high: high, critical: critical);
      final data = response.data;
      if (!response.success || data == null) return response.message;
      state = AsyncData(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final delegationRateConfigProvider =
    AsyncNotifierProvider.autoDispose<DelegationRateConfigNotifier, DelegationRateConfigModel>(
  DelegationRateConfigNotifier.new,
);
