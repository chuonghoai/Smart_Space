import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_admin/features/delegation_config/models/delegation_rate_config_model.dart';

void main() {
  test('fromJson đọc tỷ lệ + hoa hồng, thiếu trường thì về mặc định 50/40/30/20', () {
    final config = DelegationRateConfigModel.fromJson({
      'rate_low': 45,
      'commission_low': 2000,
      'commission_critical': 10000.0,
    });
    expect(config.rateLow, 45);
    expect(config.rateMedium, 40);
    expect(config.rateHigh, 30);
    expect(config.rateCritical, 20);
    expect(config.commissionLow, 2000);
    expect(config.commissionCritical, 10000);
  });

  test('bonusOf làm tròn tới đồng — cùng công thức với backend', () {
    expect(DelegationRateConfigModel.bonusOf(20000, 50), 10000);
    expect(DelegationRateConfigModel.bonusOf(7000, 30), 2100);
    expect(DelegationRateConfigModel.bonusOf(3333, 12.5), 417);
    expect(DelegationRateConfigModel.bonusOf(5000, 0), 0);
  });

  test('ratesToJson đúng tên trường của API', () {
    expect(
      DelegationRateConfigModel.ratesToJson(low: 50, medium: 40, high: 30, critical: 20),
      {'rate_low': 50, 'rate_medium': 40, 'rate_high': 30, 'rate_critical': 20},
    );
  });
}
