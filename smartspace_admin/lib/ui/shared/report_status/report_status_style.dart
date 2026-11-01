import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Màu trạng thái phản ánh theo semantic token (`app_architecture/design/design.md`):
/// chờ duyệt → Warning, đang xử lý → Info (Blue), đã xử lý → Success (Green), bị từ chối → Error.
/// Dùng chung cho mọi màn Admin để màu trạng thái không lệch nhau.
Color reportStatusColor(BuildContext context, String? status) {
  final theme = Theme.of(context);
  final semantic = AppSemanticColors.of(context);
  return switch (status?.toLowerCase()) {
    'pending' => semantic.warning,
    'processing' => semantic.info,
    'processed' || 'resolved' || 'done' => semantic.success,
    'rejected' => theme.colorScheme.error,
    _ => theme.colorScheme.onSurfaceVariant,
  };
}

String reportStatusLabel(AppLocalizations l10n, String? status) {
  return switch (status?.toLowerCase()) {
    'pending' => l10n.reportStatusPending,
    'processing' => l10n.reportStatusProcessing,
    'processed' || 'resolved' || 'done' => l10n.reportStatusProcessed,
    'rejected' => l10n.reportStatusRejected,
    _ => l10n.reportStatusUnknown,
  };
}

/// Màu + nhãn trạng thái phản ánh theo semantic token.
(Color, String) reportStatusStyle(
  BuildContext context,
  AppLocalizations l10n,
  String? status,
) =>
    (reportStatusColor(context, status), reportStatusLabel(l10n, status));
