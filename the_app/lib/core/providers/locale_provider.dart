import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _setFromLanguageCode(StorageService.getLanguage(), notify: false);
  }

  Locale _locale = const Locale(
    AppConstants.arabicLanguageCode,
    AppConstants.algeriaCountryCode,
  );

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> setLanguage(String languageCode) async {
    _setFromLanguageCode(languageCode);
    await StorageService.saveLanguage(_locale.languageCode);
  }

  void _setFromLanguageCode(String languageCode, {bool notify = true}) {
    switch (languageCode) {
      case AppConstants.englishLanguageCode:
        _locale = const Locale(
          AppConstants.englishLanguageCode,
          AppConstants.usCountryCode,
        );
        break;
      case AppConstants.frenchLanguageCode:
        _locale = const Locale(
          AppConstants.frenchLanguageCode,
          AppConstants.franceCountryCode,
        );
        break;
      case AppConstants.arabicLanguageCode:
      default:
        _locale = const Locale(
          AppConstants.arabicLanguageCode,
          AppConstants.algeriaCountryCode,
        );
        break;
    }

    if (notify) notifyListeners();
  }
}
