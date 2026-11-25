import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';
import 'package:smartspace_client/features/emergency/repositories/emergency_contact_repo.dart';

/// Dữ liệu giả lập trong bộ nhớ.
class EmergencyContactRepoMock implements EmergencyContactRepo {
  static const _delay = Duration(milliseconds: 400);

  final List<EmergencyContactModel> _contacts = [
    EmergencyContactModel(
      id: 'c1',
      name: 'Nguyễn Thị Lan',
      phone: '0912345678',
      relationship: EEmergencyRelationship.parent,
      status: EEmergencyContactStatus.accepted,
      consentChannel: EEmergencyContactConsent.selfDeclared,
      priority: 0,
      consentAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    const EmergencyContactModel(
      id: 'c2',
      name: 'Trần Minh Khoa',
      phone: '0987654321',
      relationship: EEmergencyRelationship.friend,
      status: EEmergencyContactStatus.pending,
      consentChannel: EEmergencyContactConsent.app,
      priority: 1,
      linkedUser: EmergencyContactUserModel(id: 'u2', fullName: 'Trần Minh Khoa'),
    ),
  ];

  final List<GuardianshipModel> _guardianships = [
    GuardianshipModel(
      id: 'g1',
      status: EEmergencyContactStatus.pending,
      relationship: EEmergencyRelationship.sibling,
      owner: const EmergencyContactUserModel(id: 'u3', fullName: 'Lê Hoàng Vy'),
      ownerPhone: '0909123456',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  ApiResponse<T> _ok<T>(T? data) => ApiResponse(success: true, message: 'Success', data: data);

  EmergencyContactModel _fromDto(String id, EmergencyContactDto dto, int priority) {
    final hasAccount = dto.hasAccount;
    return EmergencyContactModel(
      id: id,
      name: dto.name,
      phone: dto.phone,
      relationship: dto.relationship,
      status: hasAccount ? EEmergencyContactStatus.pending : EEmergencyContactStatus.accepted,
      consentChannel:
          hasAccount ? EEmergencyContactConsent.app : EEmergencyContactConsent.selfDeclared,
      priority: priority,
      linkedUser: hasAccount
          ? EmergencyContactUserModel(id: 'u-$id', fullName: dto.name)
          : null,
      accountEmail: hasAccount ? dto.accountEmail!.trim() : null,
      consentAt: hasAccount ? null : DateTime.now(),
    );
  }

  @override
  Future<ApiResponse<List<EmergencyContactModel>>> getMyContacts() async {
    await Future.delayed(_delay);
    return _ok(List.of(_contacts));
  }

  @override
  Future<ApiResponse<EmergencyContactModel>> createContact(EmergencyContactDto dto) async {
    await Future.delayed(_delay);
    final contact = _fromDto('c${DateTime.now().microsecondsSinceEpoch}', dto, _contacts.length);
    _contacts.add(contact);
    return _ok(contact);
  }

  @override
  Future<ApiResponse<EmergencyContactModel>> updateContact(String id, EmergencyContactDto dto) async {
    await Future.delayed(_delay);
    final index = _contacts.indexWhere((c) => c.id == id);
    final updated = _fromDto(id, dto, _contacts[index].priority);
    _contacts[index] = updated;
    return _ok(updated);
  }

  @override
  Future<ApiResponse<void>> deleteContact(String id) async {
    await Future.delayed(_delay);
    _contacts.removeWhere((c) => c.id == id);
    return _ok(null);
  }

  @override
  Future<ApiResponse<List<EmergencyContactModel>>> reorderContacts(List<String> orderedIds) async {
    await Future.delayed(_delay);
    final reordered = [
      for (var i = 0; i < orderedIds.length; i++)
        _contacts.firstWhere((c) => c.id == orderedIds[i]).copyWith(priority: i),
    ];
    _contacts
      ..clear()
      ..addAll(reordered);
    return _ok(List.of(_contacts));
  }

  @override
  Future<ApiResponse<List<GuardianshipModel>>> getGuardianships() async {
    await Future.delayed(_delay);
    return _ok(List.of(_guardianships));
  }

  @override
  Future<ApiResponse<GuardianshipModel>> acceptInvitation(String id) async {
    await Future.delayed(_delay);
    final index = _guardianships.indexWhere((g) => g.id == id);
    final g = _guardianships[index];
    final accepted = GuardianshipModel(
      id: g.id,
      status: EEmergencyContactStatus.accepted,
      relationship: g.relationship,
      owner: g.owner,
      ownerPhone: g.ownerPhone,
      consentAt: DateTime.now(),
      createdAt: g.createdAt,
    );
    _guardianships[index] = accepted;
    return _ok(accepted);
  }

  @override
  Future<ApiResponse<void>> rejectInvitation(String id) async {
    await Future.delayed(_delay);
    _guardianships.removeWhere((g) => g.id == id);
    return _ok(null);
  }

  @override
  Future<ApiResponse<void>> revokeGuardianship(String id) async {
    await Future.delayed(_delay);
    _guardianships.removeWhere((g) => g.id == id);
    return _ok(null);
  }
}
