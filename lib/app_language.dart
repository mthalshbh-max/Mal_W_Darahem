import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
const supportedLanguageCodes = <String>[
  'ar', 'en', 'fr', 'es', 'de', 'it', 'pt', 'ru',
  'zh', 'ja', 'ko', 'hi', 'ur', 'tr', 'fa', 'id',
  'ms', 'bn', 'sw', 'nl', 'pl', 'uk', 'el', 'he',
  'th', 'vi', 'sv', 'no', 'da', 'fi', 'ro', 'hu',
  'cs', 'sr', 'am', 'ta', 'fil',
];
final ValueNotifier<Locale> appLocale =
    ValueNotifier<Locale>(const Locale('ar'));

Future<void> loadAppLanguage() async {
  final prefs = await SharedPreferences.getInstance();
   final savedCode = prefs.getString('app_language') ?? 'ar';
  final code = supportedLanguageCodes.contains(savedCode)
      ? savedCode
      : 'ar';
  appLocale.value = Locale(code);
}

Future<void> saveAppLanguage(String code) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_language', code);
  appLocale.value = Locale(code);
}
