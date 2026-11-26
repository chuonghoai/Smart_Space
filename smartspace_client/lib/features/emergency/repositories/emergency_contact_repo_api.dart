import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_dto.dart';
import 'package:smartspace_client/features/emergency/models/emergency_contact_model.dart';
import 'package:smartspace_client/features/emergency/models/guardianship_model.dart';
import 'package:smartspace_client/features/emergency/repositories/emergency_contact_repo.dart';

class EmergencyContactRepoApi implements EmergencyContactRepo {
  static const _base = '/emergency-contacts';

  static List<EmergencyContactModel> _decodeContacts(dynamic json) {
    if (json is! List) return [];
    return json
        .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static EmergencyContactModel _decodeContact(dynamic json) =>
      EmergencyContactModel.fromJson(json as Map<String, dynamic>);

  @override
  Future<ApiResponse<List<EmergencyContactModel>>> getMyContacts() {
    return apiClient.get<List<EmergencyContactModel>>(_base, decoder: _decodeContacts);
  }

  @override
  Future<ApiResponse<EmergencyContactModel>> createContact(EmergencyContactDto dto) {
    return apiClient.post<EmergencyContactModel>(
      _base,
      data: dto.toJson(),
      decoder: _decodeContact,
    );
  }

  @override
  Future<ApiResponse<EmergencyContactModel>> updateContact(String id, EmergencyContactDto dto) {
    return apiClient.put<EmergencyContactModel>(
      '$_base/$id',
      data: dto.toJson(),
      decoder: _decodeContact,
    );
  }

  @override
  Future<ApiResponse<void>> deleteContact(String id) {
    return apiClient.delete<void>('$_base/$id', decoder: (_) {});
  }

  @override
  Future<ApiResponse<List<EmergencyContactModel>>> reorderContacts(List<String> orderedIds) {
    return apiClient.put<List<EmergencyContactModel>>(
      '$_base/order',
      data: {'contact_ids': orderedIds},
      decoder: _decodeContacts,
    );
  }

  @override
  Future<ApiResponse<List<GuardianshipModel>>> getGuardianships() {
    return apiClient.get<List<GuardianshipModel>>(
      '$_base/guardianships',
      decoder: (json) {
        if (json is! List) return [];
        return json
            .map((e) => GuardianshipModel.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<ApiResponse<GuardianshipModel>> acceptInvitation(String id) {
    return apiClient.post<GuardianshipModel>(
      '$_base/guardianships/$id/accept',
      decoder: (json) => GuardianshipModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<void>> rejectInvitation(String id) {
    return apiClient.post<void>('$_base/guardianships/$id/reject', decoder: (_) {});
  }

  @override
  Future<ApiResponse<void>> revokeGuardianship(String id) {
    return apiClient.delete<void>('$_base/guardianships/$id', decoder: (_) {});
  }
}
