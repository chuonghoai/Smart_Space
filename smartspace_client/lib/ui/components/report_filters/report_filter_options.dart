import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/feed_sort.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_client/features/reports/utils/report_status_ext.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_sheet.dart';

/// Danh sách lựa chọn dùng chung cho các chiều lọc phản ánh (giá trị `null` = Tất cả).
abstract final class ReportFilterOptions {
  static IconData sortIcon(FeedSort sort) => switch (sort) {
        FeedSort.latest => Icons.schedule_rounded,
        FeedSort.nearby => Icons.near_me_outlined,
      };

  static String sortLabel(FeedSort sort, AppLocalizations l10n) => switch (sort) {
        FeedSort.latest => l10n.feedTabLatest,
        FeedSort.nearby => l10n.feedTabNearby,
      };

  static List<ReportFilterOption<FeedSort>> sorts(AppLocalizations l10n) => [
        for (final sort in FeedSort.values)
          ReportFilterOption(value: sort, label: sortLabel(sort, l10n), icon: sortIcon(sort)),
      ];

  static List<ReportFilterOption<EReportSeverity?>> severities(AppLocalizations l10n) => [
        ReportFilterOption(value: null, label: l10n.mapFilterAll),
        for (final severity in EReportSeverity.values)
          ReportFilterOption(value: severity, label: severity.getLocalizedText(l10n)),
      ];

  /// Bảng tin không hiển thị phản ánh bị từ chối nên không có lựa chọn đó.
  static List<ReportFilterOption<ReportStatus?>> feedStatuses(AppLocalizations l10n) => [
        ReportFilterOption(value: null, label: l10n.mapFilterAll),
        for (final status in const [ReportStatus.pending, ReportStatus.processing, ReportStatus.processed])
          ReportFilterOption(value: status, label: status.getLocalizedText(l10n)),
      ];

  /// Giá trị `status` của `GET /reports/my-reports`; 'rehandling' = người dùng đánh giá chưa giải quyết.
  static List<ReportFilterOption<String?>> myReportStatuses(AppLocalizations l10n) => [
        ReportFilterOption(value: null, label: l10n.mapFilterAll),
        ReportFilterOption(value: ReportStatus.pending.name, label: l10n.reportStatusPending),
        ReportFilterOption(value: ReportStatus.processing.name, label: l10n.reportStatusProcessing),
        ReportFilterOption(value: ReportStatus.processed.name, label: l10n.reportStatusProcessed),
        ReportFilterOption(value: 'rehandling', label: l10n.rehandling),
        ReportFilterOption(value: ReportStatus.rejected.name, label: l10n.reportStatusRejected),
      ];

  /// Nhãn của giá trị đang chọn trong [options]; null khi đang ở "Tất cả".
  static String? selectedLabel<T>(List<ReportFilterOption<T>> options, T selected) {
    if (selected == null) return null;
    for (final option in options) {
      if (option.value == selected) return option.label;
    }
    return null;
  }
}
