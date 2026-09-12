import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/application/home_providers.dart';
import '../data/report_repository.dart';
import '../models/report_detail_model.dart';
import '../models/staff_model.dart';

final reportDetailProvider = AsyncNotifierProviderFamily<ReportDetailNotifier, ReportDetailModel, String>(() => ReportDetailNotifier());

class ReportDetailNotifier extends FamilyAsyncNotifier<ReportDetailModel, String> {
  @override
  Future<ReportDetailModel> build(String arg) async {
    return _fetchReportDetail(arg);
  }

  Future<ReportDetailModel> _fetchReportDetail(String id) async {
    final response = await reportRepository.getReportDetail(id);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchReportDetail(arg));
  }
}

final staffsProvider = AsyncNotifierProvider<StaffsNotifier, List<StaffModel>>(() => StaffsNotifier());

class StaffsNotifier extends AsyncNotifier<List<StaffModel>> {
  @override
  Future<List<StaffModel>> build() async {
    return _fetchStaffs();
  }

  Future<List<StaffModel>> _fetchStaffs() async {
    final response = await reportRepository.getStaffs();
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStaffs());
  }
}

class ReportAssignState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ReportAssignState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });
}

class ReportAssignNotifier extends StateNotifier<ReportAssignState> {
  final Ref ref;

  ReportAssignNotifier(this.ref) : super(const ReportAssignState());

  Future<bool> assignReport({
    required String reportId,
    required String staffId,
    required String severity,
  }) async {
    state = const ReportAssignState(isLoading: true);
    try {
      final response = await reportRepository.assignReport(
        reportId,
        staffId: staffId,
        severity: severity,
      );

      if (response.success && response.data != null) {
        state = const ReportAssignState(isSuccess: true);

        // Refresh detail
        ref.invalidate(reportDetailProvider(reportId));

        // Refresh home APIs
        ref.read(adminOverviewProvider.notifier).refresh();
        ref.read(recentActivityProvider.notifier).refresh();
        ref.invalidate(recentReportProvider);

        return true;
      } else {
        state = ReportAssignState(error: response.message);
        return false;
      }
    } catch (e) {
      state = ReportAssignState(error: e.toString());
      return false;
    }
  }
}

final reportAssignProvider = StateNotifierProvider<ReportAssignNotifier, ReportAssignState>((ref) {
      return ReportAssignNotifier(ref);
    });
