import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('uz');

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('uz'),
    Locale('ru'),
    Locale('en'),
  ];

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(StorageKeys.selectedLanguage) ?? 'uz';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.selectedLanguage, languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
