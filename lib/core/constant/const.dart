import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> getStringData({
  required String docId,
  required String keys,
}) async {
  final fireStore = FirebaseFirestore.instance;

  var data = await fireStore.collection('keys').doc(docId).get();
  print('>>>>>>>>>>>>>>>>>>>>');
  print(data.data);

  log(data.data()![keys].toString());
  return data.data()![keys];
}

String getLanguagesLocaleWithCodeForTextToSpeech(String locale) {
  switch (locale) {
    case 'en_US':
    case 'es_AR':
    case 'es_MX':
    case 'es_CO':
    case 'es_ES':
    case 'fr_FR':
    case 'de_DE':
    case 'pt_PT':
    case 'pt_BR':
    case 'zh_CN':
    case 'hi_IN':
    case 'id_ID':
    case 'ru_RU':
    case 'ar_AR':
    case 'vi_VN':
    case 'tr_TR':
    case 'tl_PH':
    case 'nl_NL':
    case 'it_IT':
    case 'ta_IN':
    case 'en_GB':
    case 'zh_TW':
    case 'ja_JP':
    case 'ko_KR':
    case 'pl_PL':
    case 'sv_SE':
    case 'no_NO':
    case 'da_DK':
    case 'el_GR':
      return locale;
    default:
      return 'en_US'; // fallback
  }
}

String getLanguageName(String locale) {
  print('>>>>>>>>>>language code: $locale');
  switch (locale) {
    case 'en_US':
      return 'English (United States)';
    case 'es_AR':
      return 'Spanish (Argentina)';
    case 'es_MX':
      return 'Spanish (Mexico)';
    case 'es_CO':
      return 'Spanish (Colombia)';
    case 'es_ES':
      return 'Spanish (Spain)';
    case 'fr_FR':
      return 'French (France)';
    case 'de_DE':
      return 'German (Germany)';
    case 'pt_PT':
      return 'Portuguese (Portugal)';
    case 'pt_BR':
      return 'Portuguese (Brazil)';
    case 'zh_CN':
      return 'Chinese (Simplified)';
    case 'hi_IN':
      return 'Hindi (India)';
    case 'id_ID':
      return 'Indonesian (Indonesia)';
    case 'ru_RU':
      return 'Russian (Russia)';
    case 'ar_AR':
      return 'Arabic';
    case 'vi_VN':
      return 'Vietnamese (Vietnam)';
    case 'tr_TR':
      return 'Turkish (Turkey)';
    case 'tl_PH':
      return 'Tagalog (Philippines)';
    case 'nl_NL':
      return 'Dutch (Netherlands)';
    case 'it_IT':
      return 'Italian (Italy)';
    case 'ta_IN':
      return 'Tamil (India)';
    case 'en_GB':
      return 'English (United Kingdom)';
    case 'zh_TW':
      return 'Chinese (Traditional)';
    case 'ja_JP':
      return 'Japanese (Japan)';
    case 'ko_KR':
      return 'Korean (South Korea)';
    case 'pl_PL':
      return 'Polish (Poland)';
    case 'sv_SE':
      return 'Swedish (Sweden)';
    case 'no_NO':
      return 'Norwegian (Norway)';
    case 'da_DK':
      return 'Danish (Denmark)';
    case 'el_GR':
      return 'Greek (Greece)';
    default:
      // Try shorthand match
      final short = locale.split('_').first.toLowerCase();
      switch (short) {
        case 'es':
          return 'Spanish (Spain)';
        case 'en':
          return 'English (United States)';
        case 'fr':
          return 'French (France)';
        case 'de':
          return 'German (Germany)';
        case 'pt':
          return 'Portuguese (Portugal)';
        case 'zh':
          return 'Chinese (Simplified)';
        case 'hi':
          return 'Hindi (India)';
        case 'id':
          return 'Indonesian (Indonesia)';
        case 'ru':
          return 'Russian (Russia)';
        case 'ar':
          return 'Arabic';
        case 'vi':
          return 'Vietnamese (Vietnam)';
        case 'tr':
          return 'Turkish (Turkey)';
        case 'it':
          return 'Italian (Italy)';
        case 'ja':
          return 'Japanese (Japan)';
        case 'ko':
          return 'Korean (South Korea)';
        default:
          return 'English (United States)';
      }
  }
}

List<String> languageNames = [
  'All',
  'English (United States)',
  'Spanish (Argentina)',
  'Spanish (Mexico)',
  'Spanish (Colombia)',
  'Spanish (Spain)',
  'French (France)',
  'German (Germany)',
  'Portuguese (Portugal)',
  'Portuguese (Brazil)',
  'Chinese (Simplified)',
  'Hindi (India)',
  'Indonesian (Indonesia)',
  'Russian (Russia)',
  'Arabic',
  'Vietnamese (Vietnam)',
  'Turkish (Turkey)',
  'Tagalog (Philippines)',
  'Dutch (Netherlands)',
  'Italian (Italy)',
  'Tamil (India)',
  'English (United Kingdom)',
  'Chinese (Traditional)',
  'Japanese (Japan)',
  'Korean (South Korea)',
  'Polish (Poland)',
  'Swedish (Sweden)',
  'Norwegian (Norway)',
  'Danish (Denmark)',
  'Greek (Greece)',
];

/// Converts a language display name (as shown in the dropdown) back to a locale code.
/// Returns 'en_US' as a fallback if the name is not found.
String getLocaleFromLanguageName(String languageName) {
  switch (languageName) {
    case 'English (United States)':
      return 'en_US';
    case 'English (United Kingdom)':
      return 'en_GB';
    case 'Spanish (Argentina)':
      return 'es_AR';
    case 'Spanish (Mexico)':
      return 'es_MX';
    case 'Spanish (Colombia)':
      return 'es_CO';
    case 'Spanish (Spain)':
      return 'es_ES';
    case 'French (France)':
      return 'fr_FR';
    case 'German (Germany)':
      return 'de_DE';
    case 'Portuguese (Portugal)':
      return 'pt_PT';
    case 'Portuguese (Brazil)':
      return 'pt_BR';
    case 'Chinese (Simplified)':
      return 'zh_CN';
    case 'Chinese (Traditional)':
      return 'zh_TW';
    case 'Hindi (India)':
      return 'hi_IN';
    case 'Indonesian (Indonesia)':
      return 'id_ID';
    case 'Russian (Russia)':
      return 'ru_RU';
    case 'Arabic':
      return 'ar_AR';
    case 'Vietnamese (Vietnam)':
      return 'vi_VN';
    case 'Turkish (Turkey)':
      return 'tr_TR';
    case 'Tagalog (Philippines)':
      return 'tl_PH';
    case 'Dutch (Netherlands)':
      return 'nl_NL';
    case 'Italian (Italy)':
      return 'it_IT';
    case 'Tamil (India)':
      return 'ta_IN';
    case 'Japanese (Japan)':
      return 'ja_JP';
    case 'Korean (South Korea)':
      return 'ko_KR';
    case 'Polish (Poland)':
      return 'pl_PL';
    case 'Swedish (Sweden)':
      return 'sv_SE';
    case 'Norwegian (Norway)':
      return 'no_NO';
    case 'Danish (Denmark)':
      return 'da_DK';
    case 'Greek (Greece)':
      return 'el_GR';
    default:
      return 'en_US';
  }
}

String getVoiceIdFromLocale(String locale) {
  switch (locale) {
    case 'es_ES':
      return 'Vpv1YgvVd6CHIzOTiTt8'; // Spain
    case 'es_MX':
    case 'es_CO':
    case 'es_AR':
      return '7UB6WMKyZDj19XRGC8Sb'; // Latin
    case 'en_US':
    case 'en_GB':
      return 'qWdiyiWdNPlPyVCOLW0h'; // English
    case 'de_DE':
      return 'kkJxCnlRCckmfFvzDW5Q'; // German
    case 'fr_FR':
      return 'wyZnrAs18zdIj8UgFSV8'; // French
    case 'pt_BR':
      return 'x3mAOLD9WzlmrFCwA1S3'; // Brazilian Portuguese
    case 'pt_PT':
      return 'WuLq5z7nEcrhppO0ZQJw'; // European Portuguese
    case 'zh_CN':
    case 'zh_TW':
      return 'WuLq5z7nEcrhppO0ZQJw'; // Chinese (Simplified + Traditional)
    case 'ja_JP':
      return '3JDquces8E8bkmvbh6Bc'; // Japanese
    case 'ko_KR':
      return 'jB1Cifc2UQbq1gR3wnb0'; // Korean
    case 'el_GR':
      return 'jB1Cifc2UQbq1gR3wnb0'; // Greek
    case 'pl_PL':
      return 'WuLq5z7nEcrhppO0ZQJw'; // Polish
    case 'sv_SE':
      return 'x0u3EW21dbrORJzOq1m9'; // Swedish
    case 'no_NO':
      return '9pRpxWU0T7UFt2oEMH6n'; // Norwegian
    case 'da_DK':
      return 'ygiXC2Oa1BiHksD3WkJZ'; // Danish
    case 'nl_NL':
      return 'tL2ihlEPXxMD9w1bcSDh'; // Dutch
    case 'it_IT':
      return 'Nh2zY9kknu6z4pZy6FhD'; // Italian
    case 'hi_IN':
      return 'dFL9bzYmnpBkY6f0KZip'; // Hindi
    case 'id_ID':
      return '6xPz2opT0y5qtoRh1U1Y'; // Indonesian
    case 'ru_RU':
      return 'Nh2zY9kknu6z4pZy6FhD'; // Russian
    case 'ar_AR':
      return '6xPz2opT0y5qtoRh1U1Y'; // Arabic
    case 'vi_VN':
      return '5GqeT84PUduicivx0y5x'; // Vietnamese
    case 'tr_TR':
      return 'KediIz7pebzt5TaDHiiZ'; // Turkish
    case 'tl_PH':
      return 'tL2ihlEPXxMD9w1bcSDh'; // Tagalog
    case 'ta_IN':
      return 'ZhJ5LanYnCmLKQUXvsV7'; // Tamil
    default:
      return 'qWdiyiWdNPlPyVCOLW0h'; // Default to English
  }
}
