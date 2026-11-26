/// Mối quan hệ với người trong danh sách khẩn cấp (khớp enum backend).
enum EEmergencyRelationship {
  parent,
  spouse,
  child,
  sibling,
  relative,
  friend,
  neighbor,
  other;

  String get apiValue => name.toUpperCase();

  static EEmergencyRelationship fromApi(String? value) {
    return EEmergencyRelationship.values.firstWhere(
      (e) => e.apiValue == value?.toUpperCase(),
      orElse: () => EEmergencyRelationship.other,
    );
  }
}

/// Chỉ [accepted] mới nhận cảnh báo SOS.
enum EEmergencyContactStatus {
  pending,
  accepted,
  rejected,
  revoked;

  static EEmergencyContactStatus fromApi(String? value) {
    return EEmergencyContactStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value?.toUpperCase(),
      orElse: () => EEmergencyContactStatus.pending,
    );
  }
}

/// [app]: có tài khoản, chấp nhận lời mời và nhận push.
/// [selfDeclared]: không có tài khoản, owner tự xác nhận đồng ý, nhận SMS khi có SOS.
enum EEmergencyContactConsent {
  app,
  selfDeclared;

  String get apiValue => this == app ? 'APP' : 'SELF_DECLARED';

  static EEmergencyContactConsent fromApi(String? value) {
    return value?.toUpperCase() == 'APP'
        ? EEmergencyContactConsent.app
        : EEmergencyContactConsent.selfDeclared;
  }
}

class EmergencyContactUserModel {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const EmergencyContactUserModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory EmergencyContactUserModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactUserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName, 'avatar_url': avatarUrl};
  }
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final EEmergencyRelationship relationship;
  final EEmergencyContactStatus status;
  final EEmergencyContactConsent consentChannel;
  final int priority;
  final EmergencyContactUserModel? linkedUser;
  final String? accountEmail;
  final DateTime? consentAt;
  final DateTime? createdAt;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.status,
    required this.consentChannel,
    required this.priority,
    this.linkedUser,
    this.accountEmail,
    this.consentAt,
    this.createdAt,
  });

  bool get isSelfDeclared => consentChannel == EEmergencyContactConsent.selfDeclared;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    final linked = json['linked_user'];
    return EmergencyContactModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: EEmergencyRelationship.fromApi(json['relationship'] as String?),
      status: EEmergencyContactStatus.fromApi(json['status'] as String?),
      consentChannel: EEmergencyContactConsent.fromApi(json['consent_channel'] as String?),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      linkedUser: linked is Map<String, dynamic>
          ? EmergencyContactUserModel.fromJson(linked)
          : null,
      accountEmail: json['account_email'] as String?,
      consentAt: DateTime.tryParse(json['consent_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship.apiValue,
      'status': status.name.toUpperCase(),
      'consent_channel': consentChannel.apiValue,
      'priority': priority,
      'linked_user': linkedUser?.toJson(),
      'account_email': accountEmail,
      'consent_at': consentAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  EmergencyContactModel copyWith({int? priority}) {
    return EmergencyContactModel(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship,
      status: status,
      consentChannel: consentChannel,
      priority: priority ?? this.priority,
      linkedUser: linkedUser,
      accountEmail: accountEmail,
      consentAt: consentAt,
      createdAt: createdAt,
    );
  }
}
