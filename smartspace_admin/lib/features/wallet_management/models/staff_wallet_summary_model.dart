class StaffWalletSummaryModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final double balance;
  final DateTime? updatedAt;

  StaffWalletSummaryModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.balance,
    this.updatedAt,
  });

  factory StaffWalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return StaffWalletSummaryModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

