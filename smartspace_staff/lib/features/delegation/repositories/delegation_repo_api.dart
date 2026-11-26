import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/repositories/delegation_repo.dart';

class DelegationRepoApi implements DelegationRepo {
  static DelegationModel _delegation(dynamic json) => DelegationModel.fromJson(json as Map<String, dynamic>);

  @override
  Future<ApiResponse<DelegationPage<ColleagueModel>>> searchColleagues({String? query, int page = 0, int size = 20}) {
    return apiClient.get(
      '/staff/colleagues',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'page': page,
        'size': size,
      },
      decoder: (json) => DelegationPage.fromJson(json, ColleagueModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<DelegationReportStateModel>> getReportState(String reportId) {
    return apiClient.get(
      '/staff/delegations/report/$reportId',
      decoder: (json) => DelegationReportStateModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<DelegationModel>> create({required String reportId, required String helperId, String? note}) {
    return apiClient.post(
      '/staff/delegations',
      data: {
        'report_id': reportId,
        'helper_id': helperId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      decoder: _delegation,
    );
  }

  @override
  Future<ApiResponse<DelegationPage<DelegationModel>>> list(DelegationBox box, {int page = 0, int size = 20}) {
    return apiClient.get(
      '/staff/delegations',
      queryParameters: {'box': box.name, 'page': page, 'size': size},
      decoder: (json) => DelegationPage.fromJson(json, DelegationModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<DelegationModel>> accept(String id) =>
      apiClient.post('/staff/delegations/$id/accept', decoder: _delegation);

  @override
  Future<ApiResponse<DelegationModel>> decline(String id) =>
      apiClient.post('/staff/delegations/$id/decline', decoder: _delegation);

  @override
  Future<ApiResponse<DelegationModel>> cancel(String id) =>
      apiClient.post('/staff/delegations/$id/cancel', decoder: _delegation);
}
