import 'package:smartspace_staff/l10n/app_localizations.dart';

class DistanceFormatter {
  static String format(double distanceInMeters, AppLocalizations l10n) {
    if (distanceInMeters < 1000) {
      return l10n.distanceFromYou(distanceInMeters.round().toString(), l10n.unitMeter);
    } else {
      String kmValue = (distanceInMeters / 1000).toStringAsFixed(1);
      if (kmValue.endsWith('.0')) {
        kmValue = kmValue.substring(0, kmValue.length - 2);
      }
      return l10n.distanceFromYou(kmValue, l10n.unitKilometer);
    }
  }
}
