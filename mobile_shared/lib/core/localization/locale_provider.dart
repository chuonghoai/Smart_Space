import 'package:flutter/material.dart';
import '../storage/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('vi');

  LocaleProvider();

  Locale get locale => _locale;

  Future<void> initialize() async {
    await _loadLocale();
  }

  Future<void> _loadLocale() async {
    final languageCode = await sharedPreferencesService.get<String>(_localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'vi'].contains(locale.languageCode)) return;
    if (_locale == locale) return;

    _locale = locale;
    await sharedPreferencesService.set(_localeKey, locale.languageCode);
    notifyListeners();
  }
}

final localeProvider = LocaleProvider();
