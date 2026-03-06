// import 'package:sapere/models/langauage.dart';
// import 'package:sapere/routes/app_pages.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
//
// class LanguageProvider with ChangeNotifier {
//   int _selectedIndex = 0;
//   LanguageModel _languageModel = langList[0];
//   bool _isLoading = true;
//
//   int get selectedIndex => _selectedIndex;
//   LanguageModel get languageModel => _languageModel;
//   bool get isLoading => _isLoading;
//
//   LanguageProvider() {
//     loadSelectedLanguage();
//   }
//
//   Future<void> loadSelectedLanguage() async {
//     var savedLocale = Hive.box('box').get('local');
//     var savedLangCode = Hive.box('box').get('lang_code');
//
//     if (savedLocale != null && savedLangCode != null) {
//       int index = langList.indexWhere((lang) =>
//           lang.locale == savedLocale && lang.langCode == savedLangCode);
//
//       if (index != -1) {
//         _selectedIndex = index;
//         _languageModel = langList[index];
//       }
//     }
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> saveLanguage(Locale locale, BuildContext context) async {
//     Hive.box('box').put('local', _languageModel.locale);
//     Hive.box('box').put('lang_code', _languageModel.langCode);
//
//     print('${_languageModel.langName} selected');
//     notifyListeners();
//     await Future.delayed(const Duration(seconds: 2));
//
//     Navigator.pushNamed(context, Routes.dashboardScreen);
//   }
//
//   void updateLanguageSelection(int index) {
//     _selectedIndex = index;
//     _languageModel = langList[index];
//     notifyListeners();
//   }
// }
import 'dart:ui';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/models/langauage.dart';
import 'package:get/get.dart';

import '../core/constant/strings.dart';

class LanguageController extends GetxController {
  int selectValue = 0;
  LanguageModel languageModel = langList[0];
  bool isLoading = true;

  @override
  void onInit() {
    super.onInit();
    loadSelectedLanguage();
  }

  final LocalStorage _localStorage = LocalStorage();

  Future<void> loadSelectedLanguage() async {
    String? savedLocale =
        await _localStorage.getData(key: AppLocalKeys.localeKey);
    String? savedLangCode =
        await _localStorage.getData(key: AppLocalKeys.languageCodeKey);

    if (savedLocale != null && savedLangCode != null) {
      int index = langList.indexWhere((lang) =>
          lang.locale == savedLocale && lang.langCode == savedLangCode);

      if (index != -1) {
        selectValue = index;
        languageModel = langList[index];
      }
    }

    isLoading = false;
    update();
  }
// Save language

  Future<void> checkSaveLang() async {
    final locale = Locale(languageModel.locale, languageModel.langCode);
    Get.updateLocale(locale);
    await _localStorage.setData(
        key: AppLocalKeys.localeKey, value: languageModel.locale);
    await _localStorage.setData(
        key: AppLocalKeys.languageCodeKey, value: languageModel.langCode);

    print('${languageModel.langName} selected');
    update();
  }

  void updateLanguageSelection(int index) {
    selectValue = index;
    languageModel = langList[index];
    update();
  }
}
