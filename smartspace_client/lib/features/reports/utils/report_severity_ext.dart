import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_detail_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

extension ReportSeverityExt on EReportSeverity {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);

    switch (this) {
      case EReportSeverity.low:
        return theme.colorScheme.primary;
      case EReportSeverity.medium:
        return theme.brightness == Brightness.light
            ? const Color(0xFFF9A825)
            : const Color(0xFFFFCA28);
      case EReportSeverity.high:
        return theme.colorScheme.error;
      case EReportSeverity.critical:
        return const Color(0xFFD32F2F);
    }
  }

  String getLocalizedText(AppLocalizations l10n) {
    switch (this) {
      case EReportSeverity.low:
        return l10n.severityLow;
      case EReportSeverity.medium:
        return l10n.severityMedium;
      case EReportSeverity.high:
        return l10n.severityHigh;
      case EReportSeverity.critical:
        return l10n.severityCritical;
    }
  }
}
