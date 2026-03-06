import 'package:sapere/core/constant/images.dart';

class LanguageModel {
  String locale;
  String image;
  String langCode;
  String langName;
  LanguageModel({
    required this.locale,
    required this.image,
    required this.langCode,
    required this.langName,
  });
}

List<LanguageModel> langList = [
  LanguageModel(
      locale: 'en_US',
      image: AppImagesUrls.flagUS,
      langCode: 'US',
      langName: 'English (US)'),
  LanguageModel(
      locale: 'en_GB',
      image: AppImagesUrls.flagUK,
      langCode: 'GB',
      langName: 'English (British)'),
  LanguageModel(
    locale: 'es_ES',
    image: AppImagesUrls.flagPSpain,
    langCode: 'ES',
    langName: 'Spanish (Spain)',
  ),
  LanguageModel(
    locale: 'es_MX',
    image: AppImagesUrls.flagMexico,
    langCode: 'MX',
    langName: 'Spanish (Mexico)',
  ),
  LanguageModel(
    locale: 'es_CO',
    image: AppImagesUrls.flagColombia,
    langCode: 'CO',
    langName: 'Spanish (Colombia)',
  ),
  LanguageModel(
    locale: 'es_AR',
    image: AppImagesUrls.flagArgent,
    langCode: 'AR',
    langName: 'Spanish (Argentina)',
  ),
  LanguageModel(
      locale: 'de_DE',
      image: AppImagesUrls.flagGermany,
      langCode: 'DE',
      langName: 'German'),
  LanguageModel(
      locale: 'fr_FR',
      image: AppImagesUrls.flagFrance,
      langCode: 'FR',
      langName: 'French'),
  LanguageModel(
      locale: 'pt_PT',
      image: AppImagesUrls.flagPortugal,
      langCode: 'PT',
      langName: 'Portuguese (Portugal)'),
  LanguageModel(
      locale: 'pt_BR',
      image: AppImagesUrls.flagBrazil,
      langCode: 'BR',
      langName: 'Portuguese (Brazil)'),
  LanguageModel(
    locale: 'zh_CN',
    image: AppImagesUrls.flagChina,
    langCode: 'CN',
    langName: 'Chinese (Simplified)',
  ),
  LanguageModel(
    locale: 'zh_TW',
    image: AppImagesUrls.flagTaiwan,
    langCode: 'TW',
    langName: 'Chinese (Traditional)',
  ),
  LanguageModel(
    locale: 'ja_JP',
    image: AppImagesUrls.flagJapan,
    langCode: 'JP',
    langName: 'Japanese',
  ),
  LanguageModel(
    locale: 'ko_KR',
    image: AppImagesUrls.flagKorea,
    langCode: 'KR',
    langName: 'Korean',
  ),
  LanguageModel(
    locale: 'pl_PL',
    image: AppImagesUrls.flagPoland,
    langCode: 'PL',
    langName: 'Polish',
  ),
  LanguageModel(
    locale: 'sv_SE',
    image: AppImagesUrls.flagSweden,
    langCode: 'SE',
    langName: 'Swedish',
  ),
  LanguageModel(
    locale: 'no_NO',
    image: AppImagesUrls.flagNorway,
    langCode: 'NO',
    langName: 'Norwegian',
  ),
  LanguageModel(
    locale: 'da_DK',
    image: AppImagesUrls.flagDenmark,
    langCode: 'DK',
    langName: 'Danish',
  ),
  LanguageModel(
    locale: 'el_GR',
    image: AppImagesUrls.flagGreece,
    langCode: 'GR',
    langName: 'Greek',
  ),
  LanguageModel(
    locale: 'nl_NL',
    image: AppImagesUrls.flagDutch,
    langCode: 'NL',
    langName: 'Dutch',
  ),
  LanguageModel(
    locale: 'it_IT',
    image: AppImagesUrls.flagItalian,
    langCode: 'IT',
    langName: 'Italian',
  ),
  LanguageModel(
    locale: 'hi_IN',
    image: AppImagesUrls.flagIndia,
    langCode: 'IN',
    langName: 'Hindi',
  ),
  LanguageModel(
    locale: 'id_ID',
    image: AppImagesUrls.flagIndo,
    langCode: 'ID',
    langName: 'Indonesian',
  ),
  LanguageModel(
    locale: 'ru_RU',
    image: AppImagesUrls.flagRussia,
    langCode: 'RU',
    langName: 'Russian',
  ),
  LanguageModel(
    locale: 'ar_AR',
    image: AppImagesUrls.flagArabic,
    langCode: 'SA',
    langName: 'Arabic',
  ),
  LanguageModel(
    locale: 'vi_VN',
    image: AppImagesUrls.flagVeit,
    langCode: 'VN',
    langName: 'Vietnamese',
  ),
  LanguageModel(
    locale: 'tr_TR',
    image: AppImagesUrls.flagTurkey,
    langCode: 'TR',
    langName: 'Turkish',
  ),
  LanguageModel(
    locale: 'tl_PH',
    image: AppImagesUrls.flagPhilip,
    langCode: 'PH',
    langName: 'Tagalog',
  ),
  LanguageModel(
    locale: 'ta_IN',
    image: AppImagesUrls.flagIndia,
    langCode: 'IN',
    langName: 'Tamil',
  ),
];