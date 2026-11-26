import 'package:mobile_shared/l10n/generated/shared_localizations.dart';

class DistanceFormatter {
  static String format(double distanceInMeters, SharedLocalizations l10n) {
    if (distanceInMeters < 1000) {
      return l10n.distanceFromYou(distanceInMeters.round().toString(), 'm');
    } else {
      String kmValue = (distanceInMeters / 1000).toStringAsFixed(1);
      if (kmValue.endsWith('.0')) {
        kmValue = kmValue.substring(0, kmValue.length - 2);
      }
      return l10n.distanceFromYou(kmValue, 'km');
    }
  }
}
