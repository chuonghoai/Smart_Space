import 'package:smartspace_client/l10n/app_localizations.dart';

/// "x phút/giờ/ngày trước" cho thời điểm tạo report.
String formatReportTimeAgo(DateTime createdAt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(createdAt);

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} ${l10n.minuteAgo}';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} ${l10n.hourAgo}';
  } else {
    return '${diff.inDays} ${l10n.dayAgo}';
  }
}
