import 'package:flutter/material.dart';
import 'app_language.dart';

const Map<String, String> english = {
  'مال ودراهم': 'Money & Funds',
  'دفتر حساباتي': 'My Account Book',
  'بيانات العميل': 'Customer Details',
  'المحافظ': 'Wallets',
  'المظهر': 'Appearance',
  'الرئيسية': 'Home',
  'العمليات': 'Transactions',
  'الإعدادات': 'Settings',
};

String appText(String arabic) {
  if (appLocale.value.languageCode == 'en') {
    return english[arabic] ?? arabic;
  }
  return arabic;
}

TextDirection get appTextDirection {
  const rtlLanguages = {'ar', 'fa', 'ur', 'he'};
  return rtlLanguages.contains(appLocale.value.languageCode)
      ? TextDirection.rtl
      : TextDirection.ltr;
}
