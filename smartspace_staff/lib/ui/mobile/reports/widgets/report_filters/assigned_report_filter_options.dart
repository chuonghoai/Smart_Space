import 'package:flutter/material.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';
import 'package:smartspace_staff/features/reports/utils/report_severity_ext.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/reports/widgets/report_filters/report_filter_sheet.dart';

/// Lựa chọn cho các chiều lọc của danh sách việc được giao (giá trị `null` = Tất cả).
abstract final class AssignedReportFilterOptions {
  /// Giá trị `status` của `GET /reports/staff/assigned`. "Đang xử lý" gồm cả việc cần xử lý lại
  /// (khớp số đếm thống kê ở Home).
  static const List<String> statusValues = ['all', 'processing', 'rehandling', 'resolved'];

  static String statusLabel(String status, AppLocalizations l10n) => switch (status) {
        'processing' => l10n.reportStatusProcessing,
        'rehandling' => l10n.rehandling,
        'resolved' => l10n.reportStatusProcessed,
        _ => l10n.filterAll,
      };

  /// Kèm số việc theo trạng thái khi đã có [stats] (đếm trên toàn bộ việc, không theo bộ lọc khác).
  static List<ReportFilterOption<String>> statuses(AppLocalizations l10n, ReportStatisticsModel? stats) => [
        for (final status in statusValues)
          ReportFilterOption(
            value: status,
            label: stats == null ? statusLabel(status, l10n) : '${statusLabel(status, l10n)} (${_count(status, stats)})',
          ),
      ];

  static int _count(String status, ReportStatisticsModel stats) => switch (status) {
        'processing' => stats.processing,
        'rehandling' => stats.rehandling,
        'resolved' => stats.resolved,
        _ => stats.total,
      };

  static List<ReportFilterOption<ReportSeverity?>> severities(AppLocalizations l10n) => [
        ReportFilterOption(value: null, label: l10n.filterAll),
        for (final severity in const [
          ReportSeverity.low,
          ReportSeverity.medium,
          ReportSeverity.high,
          ReportSeverity.critical,
        ])
          ReportFilterOption(value: severity, label: severity.getLocalizedText(l10n)),
      ];

  static IconData sortIcon(StaffReportSort sort) => switch (sort) {
        StaffReportSort.latest => Icons.schedule_rounded,
        StaffReportSort.oldest => Icons.history_rounded,
        StaffReportSort.severity => Icons.priority_high_rounded,
      };

  static String sortLabel(StaffReportSort sort, AppLocalizations l10n) => switch (sort) {
        StaffReportSort.latest => l10n.sortLatest,
        StaffReportSort.oldest => l10n.sortOldest,
        StaffReportSort.severity => l10n.sortSeverity,
      };

  static List<ReportFilterOption<StaffReportSort>> sorts(AppLocalizations l10n) => [
        for (final sort in StaffReportSort.values)
          ReportFilterOption(value: sort, label: sortLabel(sort, l10n), icon: sortIcon(sort)),
      ];
}
