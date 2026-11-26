import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class ReportDetailNotifier extends FamilyAsyncNotifier<ReportDetailModel, String> {
  @override
  Future<ReportDetailModel> build(String arg) async {
    return _fetchReportDetail(arg);
  }

  Future<ReportDetailModel> _fetchReportDetail(String reportId) async {
    final response = await reportService.getReportDetail(reportId);
    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchReportDetail(arg);
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final reportDetailProvider = AsyncNotifierProviderFamily<ReportDetailNotifier, ReportDetailModel, String>(
  () => ReportDetailNotifier(),
);

final reportDistanceProvider = FutureProvider.autoDispose.family<double, String>((ref, reportId) async {
  final report = await ref.watch(reportDetailProvider(reportId).future);
  
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw 'LOCATION_DISABLED';
  
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw 'PERMISSION_DENIED';
  }
  
  Position? position = await Geolocator.getLastKnownPosition();
  position ??= await Geolocator.getCurrentPosition(
    // ignore: deprecated_member_use
    desiredAccuracy: LocationAccuracy.high,
    // ignore: deprecated_member_use
    timeLimit: const Duration(seconds: 15),
  );
  
  return Geolocator.distanceBetween(position.latitude, position.longitude, report.latitude, report.longitude);
});
