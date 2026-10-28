class StaffWalletTransactionModel {
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

  StaffWalletTransactionModel({
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

  factory StaffWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return StaffWalletTransactionModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'balance_after': balanceAfter,
      'report_id': reportId,
      'report_title': reportTitle,
      'title_i18n_key': titleI18nKey,
      'title_params': titleParams,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

