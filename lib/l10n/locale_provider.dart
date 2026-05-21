import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class LocaleProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  static final LocaleProvider _instance = LocaleProvider._internal();
  factory LocaleProvider() => _instance;
  LocaleProvider._internal();

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code');

    if (saved != null) {
      _languageCode = saved;
    } else {
      // İlk kurulum — cihaz dilini algıla
      final String deviceLang = Platform.localeName.split('_')[0];

      const supportedLanguages = ['en', 'tr', 'es', 'pt', 'fr', 'de', 'ko', 'ja', 'ru', 'zh', 'it'];

      if (supportedLanguages.contains(deviceLang)) {
        _languageCode = deviceLang;
        await prefs.setString('language_code', deviceLang);
      } else {
        _languageCode = 'en';
      }
    }
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    notifyListeners();
  }
}
