import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sapere/features/local_reader/models/local_book.dart';
import 'package:sapere/features/local_reader/models/local_voice.dart';
import 'package:sapere/features/local_reader/presentation/controllers/local_reader_controller.dart';
import 'package:sapere/features/local_reader/presentation/views/reader_screen.dart';
import 'package:sapere/features/local_reader/services/bimodal_sync_coordinator.dart';
import 'package:sapere/features/local_reader/services/local_library_service.dart';
import 'package:sapere/features/local_reader/services/text_tokenizer_service.dart';
import 'package:sapere/features/local_reader/services/tts_engine_service.dart';

import 'fake_tts_driver.dart';

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'readerResumeHere': 'You left off here',
          'readerFinished': 'Finished',
          'readerProgress': '@p% read',
          'readerTypography': 'Text',
          'readerVoice': 'Voice',
          'readerAmbient': 'Ambient',
          'readerTheme': 'Theme',
          'readerMaskOff': 'Off',
          'readerMaskLines': '@n lines',
        },
      };
}

LocalBook _book({int progress = 0}) {
  final paragraphs = [
    'Hola mundo. Segunda frase del primer párrafo.',
    'Tercera frase en otro párrafo.',
  ];
  return LocalBook(
    id: 'libro_ui',
    title: 'Libro de prueba',
    languageCode: 'es_ES',
    paragraphs: paragraphs,
    sentences: TextTokenizerService().splitParagraphs(paragraphs),
    progressSentence: progress,
  );
}

void main() {
  late Directory tmp;
  late LocalLibraryService library;
  late FakeTtsDriver driver;
  late TtsEngineService engine;
  late BimodalSyncCoordinator coordinator;
  late LocalReaderController controller;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('local_reader_ui_');
    library = await LocalLibraryService.createAt(tmp);
    driver = FakeTtsDriver(
      voiceList: [LocalVoice.fromEngine(name: 'es-es-x-a-local', locale: 'es-ES')],
    );
    engine = TtsEngineService(driver: driver);
    coordinator = BimodalSyncCoordinator(ttsEngine: engine);
    controller = LocalReaderController(
      coordinator: coordinator,
      libraryService: library,
      ttsEngine: engine,
    );
  });

  tearDown(() async {
    await controller.pause();
    controller.onClose();
    coordinator.dispose();
    await driver.dispose();
    Get.reset();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> pumpReader(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (_, child) => GetMaterialApp(
          translations: _TestTranslations(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: child,
        ),
        child: ReaderScreen(controller: controller),
      ),
    );
    await tester.pump();
  }

  group('ReaderScreen', () {
    testWidgets('pinta las oraciones del libro y el título', (tester) async {
      await tester.runAsync(() => controller.openBook(_book()));
      await pumpReader(tester);

      expect(find.text('Libro de prueba'), findsOneWidget);
      expect(find.textContaining('Hola mundo', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Tercera frase', findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('reader_paragraph_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('reader_paragraph_1')), findsOneWidget);
    });

    testWidgets('marcador "aquí te quedaste" visible al abrir y desaparece al pulsar play',
        (tester) async {
      await tester.runAsync(() => controller.openBook(_book(progress: 1)));
      await pumpReader(tester);

      expect(controller.showResumeMarker.value, isTrue);
      expect(find.byKey(const ValueKey('reader_resume_marker')), findsOneWidget);
      expect(find.text('You left off here'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reader_play_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(controller.isPlaying.value, isTrue);
      expect(controller.showResumeMarker.value, isFalse);
      expect(find.byKey(const ValueKey('reader_resume_marker')), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await controller.pause();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.isPlaying.value, isFalse);
      await tester.runAsync(controller.saveProgressNow);
    });

    testWidgets('tocar una oración salta a ella', (tester) async {
      await tester.runAsync(() => controller.openBook(_book()));
      await pumpReader(tester);
      expect(controller.currentSentence.value, 0);

      await tester.tap(find.byKey(const ValueKey('reader_paragraph_1')));
      await tester.pump();

      expect(controller.currentSentence.value, 2);
      expect(controller.book.value?.progressSentence, 2);
      await tester.runAsync(controller.saveProgressNow);
    });

    testWidgets('el sheet de ajustes abre y cambia el tema', (tester) async {
      await tester.runAsync(() => controller.openBook(_book()));
      await pumpReader(tester);
      expect(controller.settings.value.theme, 'paper');

      await tester.tap(find.byKey(const ValueKey('reader_settings_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reader_theme_sepia')), findsOneWidget);
      // updateSettings escribe en disco: IO real fuera del FakeAsync.
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('reader_theme_sepia')));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      expect(controller.settings.value.theme, 'sepia');

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFFF1E4CC));
    });
  });
}
