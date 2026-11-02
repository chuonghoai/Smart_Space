import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

/// Khung thời gian để lọc báo cáo và mật độ phản ánh trên bản đồ Admin.
enum ReportTimeframe {
  all('all'),
  month1('1m'),
  month3('3m'),
  month6('6m'),
  month9('9m'),
  month12('12m');

  final String code;
  const ReportTimeframe(this.code);

  static ReportTimeframe fromCode(String? code) {
    if (code == null) return ReportTimeframe.all;
    for (final tf in ReportTimeframe.values) {
      if (tf.code.toLowerCase() == code.toLowerCase()) return tf;
    }
    return ReportTimeframe.all;
  }

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return code;
    switch (this) {
      case ReportTimeframe.all:
        return l10n.timeframeAll;
      case ReportTimeframe.month1:
        return l10n.timeframe1Month;
      case ReportTimeframe.month3:
        return l10n.timeframe3Months;
      case ReportTimeframe.month6:
        return l10n.timeframe6Months;
      case ReportTimeframe.month9:
        return l10n.timeframe9Months;
      case ReportTimeframe.month12:
        return l10n.timeframe12Months;
    }
  }
}

