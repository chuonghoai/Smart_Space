import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/data/report_repository.dart';
import 'package:smartspace_admin/features/reports/models/auto_assign_models.dart';

class AutoAssignLogsFilter {
  final String outcome;
  final String source;
  final String? categoryId;
  final int page;
  final int size;

  const AutoAssignLogsFilter({
    this.outcome = 'all',
    this.source = 'all',
    this.categoryId,
    this.page = 1,
    this.size = 12,
  });

  AutoAssignLogsFilter copyWith({
    String? outcome,
    String? source,
    String? categoryId,
    bool clearCategory = false,
    int? page,
    int? size,
  }) {
    return AutoAssignLogsFilter(
      outcome: outcome ?? this.outcome,
      source: source ?? this.source,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}

final autoAssignConfigProvider =
    FutureProvider<AutoAssignConfigModel>((ref) async {
  final response = await reportRepository.getAutoAssignConfig();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});

final autoAssignAnalyticsProvider =
    FutureProvider<AutoAssignAnalyticsModel>((ref) async {
  final response = await reportRepository.getAutoAssignAnalytics();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});

final autoAssignLogsFilterProvider = StateProvider<AutoAssignLogsFilter>(
  (ref) => const AutoAssignLogsFilter(),
);

final autoAssignLogsProvider =
    FutureProvider<AssignmentDecisionLogPageModel>((ref) async {
  final filter = ref.watch(autoAssignLogsFilterProvider);
  final response = await reportRepository.getAutoAssignLogs(
    outcome: filter.outcome,
    source: filter.source,
    categoryId: filter.categoryId,
    page: filter.page,
    size: filter.size,
  );
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});
