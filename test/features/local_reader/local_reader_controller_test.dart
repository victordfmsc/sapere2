import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/models/local_book.dart';
import 'package:sapere/features/local_reader/models/local_voice.dart';
import 'package:sapere/features/local_reader/presentation/controllers/local_reader_controller.dart';
import 'package:sapere/features/local_reader/services/bimodal_sync_coordinator.dart';
import 'package:sapere/features/local_reader/services/local_library_service.dart';
import 'package:sapere/features/local_reader/services/text_tokenizer_service.dart';
import 'package:sapere/features/local_reader/services/tts_engine_service.dart';

import 'fake_tts_driver.dart';

final voiceEsA = LocalVoice.fromEngine(name: 'es-es-x-a-local', locale: 'es-ES');
final voiceEsNeural = LocalVoice.fromEngine(name: 'es-es-x-b-network', locale: 'es-ES');
final voiceEsMx = LocalVoice.fromEngine(name: 'es-mx-x-c-local', locale: 'es-MX');
final voiceEn = LocalVoice.fromEngine(name: 'en-us-x-d-network', locale: 'en-US');

LocalBook _book({int progress = 0, String? preferredVoiceId}) {
  final paragraphs = ['Hola mundo. Segunda frase.', 'Tercera frase.'];
  return LocalBook(
    id: 'libro1',
    title: 'Libro',
    languageCode: 'es_ES',
    paragraphs: paragraphs,
    sentences: TextTokenizerService().splitParagraphs(paragraphs),
    progressSentence: progress,
    preferredVoiceId: preferredVoiceId,
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
    tmp = await Directory.systemTemp.createTemp('local_reader_ctrl_');
    library = await LocalLibraryService.createAt(tmp);
    driver = FakeTtsDriver(voiceList: [voiceEn, voiceEsA, voiceEsMx, voiceEsNeural]);
    engine = TtsEngineService(driver: driver);
    coordinator = BimodalSyncCoordinator(ttsEngine: engine);
    controller = LocalReaderController(
      coordinator: coordinator,
      libraryService: library,
      ttsEngine: engine,
    );
  });

  tearDown(() async {
    await controller.saveProgressNow();
    controller.onClose();
    coordinator.dispose();
    await driver.dispose();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('LocalReaderController', () {
    test('openBook: voz por defecto, progreso y marcador de reanudar', () async {
      final book = _book(progress: 1);
      await library.saveBook(book);
      await controller.openBook(book);

      expect(controller.book.value?.id, 'libro1');
      expect(controller.currentSentence.value, 1);
      expect(controller.showResumeMarker.value, isTrue);
      expect(controller.isPlaying.value, isFalse);
      expect(controller.voicesLoading.value, isFalse);
      expect(controller.availableVoices, [voiceEsNeural, voiceEsA, voiceEsMx]);
      expect(controller.selectedVoice.value, voiceEsNeural,
          reason: 'español → primera de la lista (neural exacta primero)');
      expect(driver.voice, voiceEsNeural);
      expect(driver.rate, TtsEngineService.engineRateOf(1.0));
    });

    test('openBook sin progreso no muestra el marcador', () async {
      await controller.openBook(_book());
      expect(controller.showResumeMarker.value, isFalse);
    });

    test('openBook respeta la voz preferida del libro', () async {
      await controller.openBook(_book(preferredVoiceId: voiceEsMx.id));
      expect(controller.selectedVoice.value, voiceEsMx);
    });

    test('openBook usa settings.voiceByLanguage si el libro no fija voz', () async {
      await library.saveSettings(
        (await library.getSettings()).copyWith(voiceByLanguage: {'es_ES': voiceEsA.id}, rate: 1.5),
      );
      await controller.openBook(_book());
      expect(controller.selectedVoice.value, voiceEsA);
      expect(controller.settings.value.rate, 1.5);
      expect(driver.rate, TtsEngineService.engineRateOf(1.5));
    });

    test('voz preferida inexistente cae a la voz por defecto', () async {
      await controller.openBook(_book(preferredVoiceId: 'borrada|xx-XX'));
      expect(controller.selectedVoice.value, voiceEsNeural);
    });

    test('jumpTo oculta el marcador y mueve la oración sin reproducir', () async {
      await controller.openBook(_book(progress: 1));
      expect(controller.showResumeMarker.value, isTrue);
      await controller.jumpTo(2);
      expect(controller.showResumeMarker.value, isFalse);
      expect(controller.currentSentence.value, 2);
      expect(controller.isPlaying.value, isFalse);
      expect(driver.spoken, isEmpty);
    });

    test('el progreso se persiste con debounce de 1 s', () async {
      final book = _book();
      await library.saveBook(book);
      await controller.openBook(book);
      await controller.jumpTo(2);
      expect((await library.getBook('libro1'))!.progressSentence, 0,
          reason: 'todavía no ha vencido el debounce');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect((await library.getBook('libro1'))!.progressSentence, 2);
    });

    test('onClose guarda el progreso pendiente sin esperar al debounce', () async {
      final book = _book();
      await library.saveBook(book);
      await controller.openBook(book);
      await controller.jumpTo(1);
      controller.onClose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect((await library.getBook('libro1'))!.progressSentence, 1);
    });

    test('play reproduce desde la oración actual y oculta el marcador', () async {
      await controller.openBook(_book(progress: 1));
      await controller.play();
      expect(controller.showResumeMarker.value, isFalse);
      expect(controller.isPlaying.value, isTrue);
      await waitFor(() => !controller.isPlaying.value && driver.spoken.length == 2);
      expect(driver.spoken, ['Segunda frase.', 'Tercera frase.']);
      expect(controller.currentSentence.value, 2);
      expect(controller.currentWord.value, isNull);
    });

    test('togglePlay pausa y reanuda; next/previous', () async {
      await controller.openBook(_book());
      await controller.togglePlay();
      expect(controller.isPlaying.value, isTrue);
      await controller.togglePlay();
      expect(controller.isPlaying.value, isFalse);
      await controller.next();
      expect(controller.currentSentence.value, 1);
      await controller.previous();
      expect(controller.currentSentence.value, 0);
    });

    test('selectVoice persiste en settings y en el libro', () async {
      final book = _book();
      await library.saveBook(book);
      await controller.openBook(book);
      await controller.selectVoice(voiceEsA);

      expect(controller.selectedVoice.value, voiceEsA);
      expect(driver.voice, voiceEsA);
      expect((await library.getSettings()).voiceByLanguage['es_ES'], voiceEsA.id);
      expect((await library.getBook('libro1'))!.preferredVoiceId, voiceEsA.id);
    });

    test('previewVoice habla una frase corta en el idioma del libro y restaura la voz', () async {
      await controller.openBook(_book());
      await controller.previewVoice(voiceEsMx);
      expect(driver.spoken.single, startsWith('Hola'));
      expect(driver.voice, voiceEsNeural, reason: 'restaura la voz seleccionada');
      expect(controller.selectedVoice.value, voiceEsNeural);
    });

    test('setRate y updateSettings persisten', () async {
      await controller.openBook(_book());
      await controller.setRate(1.75);
      expect(controller.settings.value.rate, 1.75);
      expect(driver.rate, TtsEngineService.engineRateOf(1.75));
      await controller.updateSettings((s) => s.copyWith(theme: 'sepia', sfxEnabled: true));
      final saved = await library.getSettings();
      expect(saved.rate, 1.75);
      expect(saved.theme, 'sepia');
      expect(saved.sfxEnabled, isTrue);
    });

    test('setAmbient / setAmbientVolume persisten aunque no haya reproductor', () async {
      await controller.openBook(_book());
      await controller.setAmbient('rain');
      await controller.setAmbientVolume(0.3);
      var saved = await library.getSettings();
      expect(saved.ambientTrackId, 'rain');
      expect(saved.ambientVolume, 0.3);
      expect(controller.ambientTrackId.value, isNull, reason: 'sin BackgroundAudioService');
      await controller.setAmbient(null);
      saved = await library.getSettings();
      expect(saved.ambientTrackId, isNull);
    });
  });
}
