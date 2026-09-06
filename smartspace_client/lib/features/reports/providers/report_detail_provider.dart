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
      final report = response.data!;
      // try calculate distance
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse) {
         final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
         if (isLocationServiceEnabled) {
             final position = await Geolocator.getLastKnownPosition();
             if (position != null) {
                final distance = Geolocator.distanceBetween(position.latitude, position.longitude, report.latitude, report.longitude);
                return report.copyWith(distanceInMeters: distance);
             }
         }
      }
      return report;
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
