import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_repository.dart';
import '../models/report_statistics_model.dart';
import '../models/report_trend_model.dart';

//  Statistics Provider

class ReportStatisticsNotifier extends AsyncNotifier<ReportStatisticsModel> {
  @override
  Future<ReportStatisticsModel> build() => _fetch();

  Future<ReportStatisticsModel> _fetch() async {
    final response = await reportRepository.getReportStatistics();
    if (response.success && response.data != null) return response.data!;
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final reportStatisticsProvider =
    AsyncNotifierProvider<ReportStatisticsNotifier, ReportStatisticsModel>(
      ReportStatisticsNotifier.new,
    );

//  Trend Provider (period: daily, weekly, monthly)

class ReportTrendNotifier
    extends FamilyAsyncNotifier<List<ReportTrendItem>, String> {
  @override
  Future<List<ReportTrendItem>> build(String arg) => _fetch(arg);

  Future<List<ReportTrendItem>> _fetch(String period) async {
    final response = await reportRepository.getReportTrend(period);
    if (response.success && response.data != null) return response.data!;
    throw Exception(response.message);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final reportTrendProvider =
    AsyncNotifierProviderFamily<
      ReportTrendNotifier,
      List<ReportTrendItem>,
      String
    >(ReportTrendNotifier.new);
