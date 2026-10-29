class StaffTransactionItemModel {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? reportId;
  final String? reportTitle;
  final String? titleI18nKey;
  final String? titleParams;
  final String title;
  final DateTime createdAt;

  StaffTransactionItemModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.reportId,
    this.reportTitle,
    this.titleI18nKey,
    this.titleParams,
    required this.title,
    required this.createdAt,
  });

  bool get isIncome => type == 'COMMISSION';
  bool get isPenalty => type == 'PENALTY_DEDUCTION';
  bool get isWithdrawal => type == 'WITHDRAWAL';

  factory StaffTransactionItemModel.fromJson(Map<String, dynamic> json) {
    return StaffTransactionItemModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      reportId: json['report_id']?.toString(),
      reportTitle: json['report_title']?.toString(),
      titleI18nKey: json['title_i18n_key']?.toString(),
      titleParams: json['title_params']?.toString(),
      title: json['title']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

