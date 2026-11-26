import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';

abstract class EmergencyContactRepo {
  Future<ApiResponse<List<EmergencyContactModel>>> getMyContacts();
  Future<ApiResponse<EmergencyContactModel>> createContact(EmergencyContactDto dto);
  Future<ApiResponse<EmergencyContactModel>> updateContact(String id, EmergencyContactDto dto);
  Future<ApiResponse<void>> deleteContact(String id);
  Future<ApiResponse<List<EmergencyContactModel>>> reorderContacts(List<String> orderedIds);

  Future<ApiResponse<List<GuardianshipModel>>> getGuardianships();
  Future<ApiResponse<GuardianshipModel>> acceptInvitation(String id);
  Future<ApiResponse<void>> rejectInvitation(String id);
  Future<ApiResponse<void>> revokeGuardianship(String id);
}
