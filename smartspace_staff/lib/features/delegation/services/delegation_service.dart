import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/repositories/delegation_repo.dart';
import 'package:smartspace_staff/features/delegation/repositories/delegation_repo_api.dart';

class DelegationService {
  final DelegationRepo _repo;

  DelegationService([DelegationRepo? repo]) : _repo = repo ?? DelegationRepoApi();

  Future<ApiResponse<DelegationPage<ColleagueModel>>> searchColleagues({String? query, int page = 0}) =>
      _repo.searchColleagues(query: query, page: page);

  Future<ApiResponse<DelegationReportStateModel>> getReportState(String reportId) => _repo.getReportState(reportId);

  Future<ApiResponse<DelegationModel>> create({required String reportId, required String helperId, String? note}) =>
      _repo.create(reportId: reportId, helperId: helperId, note: note);

  Future<ApiResponse<DelegationPage<DelegationModel>>> list(DelegationBox box, {int page = 0}) =>
      _repo.list(box, page: page);

  Future<ApiResponse<DelegationModel>> accept(String id) => _repo.accept(id);

  Future<ApiResponse<DelegationModel>> decline(String id) => _repo.decline(id);

  Future<ApiResponse<DelegationModel>> cancel(String id) => _repo.cancel(id);
}

final delegationService = DelegationService();
