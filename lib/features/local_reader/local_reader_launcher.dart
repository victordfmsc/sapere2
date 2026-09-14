import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sapere/main.dart' show audioHandler;

import 'presentation/controllers/local_reader_controller.dart';
import 'presentation/views/reader_screen.dart';
import 'services/background_audio_service.dart';
import 'services/bimodal_sync_coordinator.dart';
import 'services/document_parser_service.dart';
import 'services/language_detector_service.dart';
import 'services/local_library_service.dart';
import 'services/phonetic_speech_normalizer.dart';
import 'services/sfx_keyword_service.dart';
import 'services/tts_engine_service.dart';

/// Inversa de `getLanguageName` (lib/core/constant/const.dart):
/// nombre largo → locale de la app (xx_YY). Null si no se reconoce.
String? appLocaleFromLanguageName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  const byName = <String, String>{
    'English (United States)': 'en_US',
    'Spanish (Argentina)': 'es_AR',
    'Spanish (Mexico)': 'es_MX',
    'Spanish (Colombia)': 'es_CO',
    'Spanish (Spain)': 'es_ES',
    'French (France)': 'fr_FR',
    'German (Germany)': 'de_DE',
    'Portuguese (Portugal)': 'pt_PT',
    'Portuguese (Brazil)': 'pt_BR',
    'Chinese (Simplified)': 'zh_CN',
    'Hindi (India)': 'hi_IN',
    'Indonesian (Indonesia)': 'id_ID',
    'Russian (Russia)': 'ru_RU',
    'Arabic': 'ar_AR',
    'Vietnamese (Vietnam)': 'vi_VN',
    'Turkish (Turkey)': 'tr_TR',
    'Tagalog (Philippines)': 'tl_PH',
    'Dutch (Netherlands)': 'nl_NL',
    'Italian (Italy)': 'it_IT',
    'Tamil (India)': 'ta_IN',
    'English (United Kingdom)': 'en_GB',
    'Chinese (Traditional)': 'zh_TW',
    'Japanese (Japan)': 'ja_JP',
    'Korean (South Korea)': 'ko_KR',
    'Polish (Poland)': 'pl_PL',
    'Swedish (Sweden)': 'sv_SE',
    'Norwegian (Norway)': 'no_NO',
    'Danish (Denmark)': 'da_DK',
    'Greek (Greece)': 'el_GR',
  };
  final trimmed = name.trim();
  final exact = byName[trimmed];
  if (exact != null) return exact;
  final lower = trimmed.toLowerCase();
  for (final e in byName.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }
  return null;
}

/// Abre el lector bimodal para un texto: lo parsea (o reutiliza el guardado),
/// monta los servicios, navega a [ReaderScreen] y lo desmonta todo al volver.
/// [onClosed] recibe el progreso guardado (0–1) cuando el usuario sale.
Future<void> openLocalReader({
  required String bookId,
  required String title,
  required String content,
  required String languageCode,
  String? coverPath,
  bool autoPlay = false,
  void Function(double progress)? onClosed,
}) async {
  try {
    if (audioHandler.playbackState.value.playing) await audioHandler.pause();
  } catch (e) {
    debugPrint('[openLocalReader] pause global player failed: $e');
  }

  final LocalLibraryService library;
  if (Get.isRegistered<LocalLibraryService>()) {
    library = Get.find<LocalLibraryService>();
  } else {
    library = Get.put(await LocalLibraryService.create(), permanent: true);
  }

  final lang = languageCode.trim().isNotEmpty
      ? languageCode.trim()
      : LanguageDetectorService().detect(content, fallback: 'en_US');

  final parser = PlainTextDocumentParser();
  final freshParagraphs = parser.splitParagraphs(content);
  var book = await library.getBook(bookId);
  final changed =
      book == null || book.paragraphs.join('\n') != freshParagraphs.join('\n');
  if (changed) {
    final parsed = await parser.parseString(
      content: content,
      title: title,
      bookId: bookId,
      languageCode: lang,
      coverPath: coverPath,
    );
    parsed.preferredVoiceId = book?.preferredVoiceId;
    book = parsed;
    await library.saveBook(book);
  } else if (book.title != title ||
      book.coverPath != coverPath ||
      book.languageCode != lang) {
    book
      ..title = title
      ..coverPath = coverPath
      ..languageCode = lang;
    await library.saveBook(book);
  }

  final ttsEngine = TtsEngineService();
  final coordinator = BimodalSyncCoordinator(
    ttsEngine: ttsEngine,
    normalizer: PhoneticSpeechNormalizer(await library.getPronunciationRules()),
  );
  final ambient = BackgroundAudioService();
  final sfx = SfxKeywordService();
  await sfx.loadAssetIndex();

  if (Get.isRegistered<LocalReaderController>(tag: bookId)) {
    await Get.delete<LocalReaderController>(tag: bookId, force: true);
  }
  final controller = Get.put(
    LocalReaderController(
      coordinator: coordinator,
      libraryService: library,
      ttsEngine: ttsEngine,
      ambient: ambient,
      sfx: sfx,
    ),
    tag: bookId,
  );

  await controller.openBook(book, autoApplyAmbient: true);

  await Get.to<void>(
    () => ReaderScreen(controller: controller, autoPlay: autoPlay),
  );

  await controller.pause();
  await controller.saveProgressNow();
  final double progress = (await library.getBook(bookId))?.progress ?? 0.0;
  await Get.delete<LocalReaderController>(tag: bookId, force: true);
  coordinator.dispose();
  await ttsEngine.dispose();
  await ambient.dispose();
  await sfx.dispose();
  onClosed?.call(progress);
}
