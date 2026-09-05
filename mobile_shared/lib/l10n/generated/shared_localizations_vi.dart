// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'shared_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SharedLocalizationsVi extends SharedLocalizations {
  SharedLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String distanceFromYou(String value, String unit) {
    return 'Cách bạn $value $unit';
  }
}
