import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['fr', 'en', 'ar'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('fr');
    notifyListeners();
  }
}
