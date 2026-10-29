class StaffBankAccountModel {
  final String id;
  final String? userId;
  final String? bankCode;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final DateTime? createdAt;

  StaffBankAccountModel({
    required this.id,
    this.userId,
    this.bankCode,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.createdAt,
  });

  factory StaffBankAccountModel.fromJson(Map<String, dynamic> json) {
    return StaffBankAccountModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      bankCode: json['bank_code']?.toString(),
      bankName: json['bank_name']?.toString() ?? '',
      bankAccountNumber: json['bank_account_number']?.toString() ?? '',
      bankAccountName: json['bank_account_name']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_code': bankCode,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffBankAccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

