import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/constants/use_mock.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';
import 'package:smartspace_client/features/emergency/repositories/emergency_contact_repo.dart';
import 'package:smartspace_client/features/emergency/repositories/emergency_contact_repo_api.dart';
import 'package:smartspace_client/features/emergency/repositories/emergency_contact_repo_mock.dart';

class EmergencyContactService {
  final EmergencyContactRepo repo;

  const EmergencyContactService({required this.repo});

  Future<ApiResponse<List<EmergencyContactModel>>> getMyContacts() => repo.getMyContacts();

  Future<ApiResponse<EmergencyContactModel>> createContact(EmergencyContactDto dto) =>
      repo.createContact(dto);

  Future<ApiResponse<EmergencyContactModel>> updateContact(String id, EmergencyContactDto dto) =>
      repo.updateContact(id, dto);

  Future<ApiResponse<void>> deleteContact(String id) => repo.deleteContact(id);

  Future<ApiResponse<List<EmergencyContactModel>>> reorderContacts(List<String> orderedIds) =>
      repo.reorderContacts(orderedIds);

  Future<ApiResponse<List<GuardianshipModel>>> getGuardianships() => repo.getGuardianships();

  Future<ApiResponse<GuardianshipModel>> acceptInvitation(String id) => repo.acceptInvitation(id);

  Future<ApiResponse<void>> rejectInvitation(String id) => repo.rejectInvitation(id);

  Future<ApiResponse<void>> revokeGuardianship(String id) => repo.revokeGuardianship(id);
}

final emergencyContactService = EmergencyContactService(
  repo: useMock ? EmergencyContactRepoMock() : EmergencyContactRepoApi(),
);
