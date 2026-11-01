import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';

abstract class DelegationRepo {
  Future<ApiResponse<DelegationPage<ColleagueModel>>> searchColleagues({String? query, int page = 0, int size = 20});

  Future<ApiResponse<DelegationReportStateModel>> getReportState(String reportId);

  Future<ApiResponse<DelegationModel>> create({required String reportId, required String helperId, String? note});

  Future<ApiResponse<DelegationPage<DelegationModel>>> list(DelegationBox box, {int page = 0, int size = 20});

  Future<ApiResponse<DelegationModel>> accept(String id);

  Future<ApiResponse<DelegationModel>> decline(String id);

  Future<ApiResponse<DelegationModel>> cancel(String id);
}
