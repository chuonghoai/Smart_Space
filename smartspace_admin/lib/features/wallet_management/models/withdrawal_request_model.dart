class WithdrawalRequestModel {
  final String id;
  final String userId;
  final String staffName;
  final String staffEmail;
  final String? staffPhone;
  final String? staffAvatar;
  final double amount;
  final String bankCode;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String? qrCodeUrl;
  final String status;
  final String? note;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? processedAt;

  WithdrawalRequestModel({
    required this.id,
    required this.userId,
    required this.staffName,
    required this.staffEmail,
    this.staffPhone,
    this.staffAvatar,
    required this.amount,
    required this.bankCode,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.qrCodeUrl,
    required this.status,
    this.note,
    this.adminNote,
    this.createdAt,
    this.processedAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      staffEmail: json['staff_email']?.toString() ?? '',
      staffPhone: json['staff_phone']?.toString(),
      staffAvatar: json['staff_avatar']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankCode: json['bank_code']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      bankAccountNumber: json['bank_account_number']?.toString() ?? '',
      bankAccountName: json['bank_account_name']?.toString() ?? '',
      qrCodeUrl: json['qr_code_url']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      note: json['note']?.toString(),
      adminNote: json['admin_note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
    );
  }
}

