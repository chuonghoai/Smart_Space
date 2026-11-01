/// Tỷ lệ bonus nhờ làm giùm (%) theo mức độ, kèm hoa hồng hiện tại để tính ví dụ số tiền.
class DelegationRateConfigModel {
  final double rateLow;
  final double rateMedium;
  final double rateHigh;
  final double rateCritical;
  final double commissionLow;
  final double commissionMedium;
  final double commissionHigh;
  final double commissionCritical;

  const DelegationRateConfigModel({
    required this.rateLow,
    required this.rateMedium,
    required this.rateHigh,
    required this.rateCritical,
    required this.commissionLow,
    required this.commissionMedium,
    required this.commissionHigh,
    required this.commissionCritical,
  });

  factory DelegationRateConfigModel.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback) => (json[key] as num?)?.toDouble() ?? fallback;
    return DelegationRateConfigModel(
      rateLow: read('rate_low', 50),
      rateMedium: read('rate_medium', 40),
      rateHigh: read('rate_high', 30),
      rateCritical: read('rate_critical', 20),
      commissionLow: read('commission_low', 0),
      commissionMedium: read('commission_medium', 0),
      commissionHigh: read('commission_high', 0),
      commissionCritical: read('commission_critical', 0),
    );
  }

  /// Body của `PUT /admin/wallet/config/delegation` (chỉ gửi tỷ lệ).
  static Map<String, dynamic> ratesToJson({
    required double low,
    required double medium,
    required double high,
    required double critical,
  }) =>
      {'rate_low': low, 'rate_medium': medium, 'rate_high': high, 'rate_critical': critical};

  /// Bonus làm tròn tới đồng — cùng công thức với backend.
  static double bonusOf(double commission, double ratePercent) =>
      (commission * ratePercent / 100).roundToDouble();
}
