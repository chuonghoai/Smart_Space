class StaffWalletModel {
  final String id;
  final double balance;
  final String? userId;
  final DateTime? updatedAt;

  StaffWalletModel({
    required this.id,
    required this.balance,
    this.userId,
    this.updatedAt,
  });

  factory StaffWalletModel.fromJson(Map<String, dynamic> json) {
    return StaffWalletModel(
      id: json['id']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      userId: json['user_id']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'user_id': userId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

