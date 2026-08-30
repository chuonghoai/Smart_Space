import 'package:flutter/material.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';

extension ReportStatusExt on ReportStatus {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = theme.brightness == Brightness.light
        ? const Color(0xFFF9A825)
        : const Color(0xFFFFCA28);

    switch (this) {
      case ReportStatus.processed:
        return theme.colorScheme.secondary;
      case ReportStatus.processing:
      case ReportStatus.pending:
        return warningColor;
      case ReportStatus.rejected:
        return theme.colorScheme.error;
      case ReportStatus.unknown:
        return theme.colorScheme.primary;
    }
  }

  String getLocalizedText(AppLocalizations l10n) {
    switch (this) {
      case ReportStatus.processed:
        return l10n.reportStatusProcessed;
      case ReportStatus.processing:
        return l10n.reportStatusProcessing;
      case ReportStatus.pending:
        return l10n.reportStatusPending;
      case ReportStatus.rejected:
        return l10n.reportStatusRejected;
      case ReportStatus.unknown:
        return l10n.reportStatusUnknown;
    }
  }
}
