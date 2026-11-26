import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';

/// Payload tạo/sửa liên hệ khẩn cấp.
class EmergencyContactDto {
  final String name;
  final String phone;
  final EEmergencyRelationship relationship;

  /// Email tài khoản SmartSpace của người quen; trống nếu họ không dùng app.
  final String? accountEmail;

  /// Owner xác nhận người quen đã đồng ý (bắt buộc khi không có [accountEmail]).
  final bool consentConfirmed;

  const EmergencyContactDto({
    required this.name,
    required this.phone,
    required this.relationship,
    this.accountEmail,
    this.consentConfirmed = false,
  });

  bool get hasAccount => accountEmail?.trim().isNotEmpty ?? false;

  factory EmergencyContactDto.fromJson(Map<String, dynamic> json) {
    return EmergencyContactDto(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: EEmergencyRelationship.fromApi(json['relationship'] as String?),
      accountEmail: json['account_email'] as String?,
      consentConfirmed: json['consent_confirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship': relationship.apiValue,
      'account_email': hasAccount ? accountEmail!.trim() : null,
      'consent_confirmed': consentConfirmed,
    };
  }
}
