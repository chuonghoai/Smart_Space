import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';

/// Quan hệ bảo hộ nhìn từ phía người được thêm vào danh sách khẩn cấp của người khác.
class GuardianshipModel {
  final String id;
  final EEmergencyContactStatus status;
  final EEmergencyRelationship relationship;
  final EmergencyContactUserModel owner;
  final String? ownerPhone;
  final DateTime? consentAt;
  final DateTime? createdAt;

  const GuardianshipModel({
    required this.id,
    required this.status,
    required this.relationship,
    required this.owner,
    this.ownerPhone,
    this.consentAt,
    this.createdAt,
  });

  bool get isPending => status == EEmergencyContactStatus.pending;

  factory GuardianshipModel.fromJson(Map<String, dynamic> json) {
    return GuardianshipModel(
      id: json['id'] as String? ?? '',
      status: EEmergencyContactStatus.fromApi(json['status'] as String?),
      relationship: EEmergencyRelationship.fromApi(json['relationship'] as String?),
      owner: EmergencyContactUserModel.fromJson(
        (json['owner'] as Map<String, dynamic>?) ?? const {},
      ),
      ownerPhone: json['owner_phone'] as String?,
      consentAt: DateTime.tryParse(json['consent_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name.toUpperCase(),
      'relationship': relationship.apiValue,
      'owner': owner.toJson(),
      'owner_phone': ownerPhone,
      'consent_at': consentAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
