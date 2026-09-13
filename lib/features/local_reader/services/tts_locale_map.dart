/// Locale de la app (xx_YY) → locale BCP-47 que entienden los motores TTS.
const Map<String, String> ttsLocaleForApp = {
  'en_US': 'en-US',
  'en_GB': 'en-GB',
  'es_AR': 'es-AR',
  'es_MX': 'es-MX',
  'es_CO': 'es-CO',
  'es_ES': 'es-ES',
  'fr_FR': 'fr-FR',
  'de_DE': 'de-DE',
  'pt_PT': 'pt-PT',
  'pt_BR': 'pt-BR',
  'zh_CN': 'zh-CN',
  'hi_IN': 'hi-IN',
  'id_ID': 'id-ID',
  'ru_RU': 'ru-RU',
  'ar_AR': 'ar-SA',
  'vi_VN': 'vi-VN',
  'tr_TR': 'tr-TR',
  'tl_PH': 'fil-PH',
  'nl_NL': 'nl-NL',
  'it_IT': 'it-IT',
  'ta_IN': 'ta-IN',
  'zh_TW': 'zh-TW',
  'ja_JP': 'ja-JP',
  'ko_KR': 'ko-KR',
  'pl_PL': 'pl-PL',
  'sv_SE': 'sv-SE',
  'no_NO': 'nb-NO',
  'da_DK': 'da-DK',
  'el_GR': 'el-GR',
};

/// Locale TTS completo para un locale de la app; si no está mapeado,
/// convierte `xx_YY` → `xx-YY`.
String ttsLocaleOf(String appLocale) =>
    ttsLocaleForApp[appLocale] ?? appLocale.replaceAll('_', '-');

/// Idioma TTS sin región (`es_ES` → `es`, `tl_PH` → `fil`, `no_NO` → `nb`).
String ttsLanguageOf(String appLocale) {
  final full = ttsLocaleOf(appLocale);
  final dash = full.indexOf('-');
  return (dash == -1 ? full : full.substring(0, dash)).toLowerCase();
}
