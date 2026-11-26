import 'package:flutter/material.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

extension ReportSeverityExt on ReportSeverity {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);

    switch (this) {
      case ReportSeverity.low:
        return theme.colorScheme.primary;
      case ReportSeverity.medium:
        return theme.brightness == Brightness.light
            ? const Color(0xFFF9A825)
            : const Color(0xFFFFCA28);
      case ReportSeverity.high:
        return theme.colorScheme.error;
      case ReportSeverity.critical:
        return const Color(0xFFD32F2F);
      case ReportSeverity.unknown:
        return theme.dividerColor;
    }
  }

  String getLocalizedText(AppLocalizations l10n) {
    switch (this) {
      case ReportSeverity.low:
        return l10n.severityLow;
      case ReportSeverity.medium:
        return l10n.severityMedium;
      case ReportSeverity.high:
        return l10n.severityHigh;
      case ReportSeverity.critical:
        return l10n.severityCritical;
      case ReportSeverity.unknown:
        return 'Unknown';
    }
  }
}
