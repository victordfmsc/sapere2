import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/models/local_book.dart';
import 'package:sapere/features/local_reader/services/bimodal_sync_coordinator.dart';
import 'package:sapere/features/local_reader/services/text_tokenizer_service.dart';
import 'package:sapere/features/local_reader/services/tts_engine_service.dart';

import 'fake_tts_driver.dart';

LocalBook _book({int progress = 0}) {
  final paragraphs = ['Hola mundo cruel. Segunda frase aquí.', 'Tercera y última.'];
  return LocalBook(
    id: 'b1',
    title: 'Libro',
    languageCode: 'es_ES',
    paragraphs: paragraphs,
    sentences: TextTokenizerService().splitParagraphs(paragraphs),
    progressSentence: progress,
  );
}

void main() {
  late FakeTtsDriver driver;
  late TtsEngineService engine;
  late BimodalSyncCoordinator coordinator;

  setUp(() {
    driver = FakeTtsDriver();
    engine = TtsEngineService(driver: driver);
    coordinator = BimodalSyncCoordinator(ttsEngine: engine);
  });

  tearDown(() async {
    coordinator.dispose();
    await driver.dispose();
  });

  group('BimodalSyncCoordinator', () {
    test('load fija la oración de progreso y no reproduce', () {
      coordinator.load(_book(progress: 2));
      expect(coordinator.sentenceIndex, 2);
      expect(coordinator.playing, isFalse);
      coordinator.load(_book(progress: 99));
      expect(coordinator.sentenceIndex, 2);
    });

    test('avanza oración a oración hasta terminar y emite finished', () async {
      final book = _book();
      coordinator.load(book);
      final seen = <int>[];
      coordinator.currentSentence.listen(seen.add);
      var finished = 0;
      coordinator.finished.listen((_) => finished++);

      await coordinator.playFrom(0);
      expect(coordinator.playing, isTrue);
      await waitFor(() => finished == 1);

      expect(driver.spoken, ['Hola mundo cruel.', 'Segunda frase aquí.', 'Tercera y última.']);
      expect(seen, containsAllInOrder([0, 1, 2]));
      expect(coordinator.sentenceIndex, 2);
      expect(coordinator.playing, isFalse);
    });

    test('índice de palabra correcto según el progreso del motor', () async {
      coordinator.load(_book());
      final words = <int?>[];
      coordinator.currentWord.listen(words.add);
      await coordinator.playFrom(0);
      await waitFor(() => driver.spoken.length >= 2);
      // Primera oración "Hola mundo cruel." → palabras 0,1,2 en orden.
      final nonNull = words.whereType<int>().toList();
      expect(nonNull.take(3).toList(), [0, 1, 2]);
      await coordinator.stop();
    });

    test('pause y resume repiten la oración en curso', () async {
      coordinator.load(_book());
      await coordinator.playFrom(1);
      await waitFor(() => driver.spoken.length == 1);
      await coordinator.pause();
      expect(coordinator.playing, isFalse);
      expect(coordinator.sentenceIndex, 1);
      final stopsBefore = driver.stopCalls;
      expect(stopsBefore, greaterThanOrEqualTo(1));

      await coordinator.resume();
      await waitFor(() => driver.spoken.length >= 2);
      expect(driver.spoken[0], 'Segunda frase aquí.');
      expect(driver.spoken[1], 'Segunda frase aquí.');
      await coordinator.stop();
    });

    test('next/previous en pausa solo mueven el índice', () async {
      coordinator.load(_book());
      await coordinator.next();
      expect(coordinator.sentenceIndex, 1);
      await coordinator.next();
      await coordinator.next();
      expect(coordinator.sentenceIndex, 2, reason: 'se satura en la última');
      await coordinator.previous();
      expect(coordinator.sentenceIndex, 1);
      await coordinator.seek(-5);
      expect(coordinator.sentenceIndex, 0);
      expect(driver.spoken, isEmpty);
    });

    test('next reproduciendo salta y sigue reproduciendo', () async {
      coordinator.load(_book());
      await coordinator.playFrom(0);
      await waitFor(() => driver.spoken.length == 1);
      await coordinator.next();
      expect(coordinator.playing, isTrue);
      await waitFor(() => driver.spoken.length >= 2);
      expect(driver.spoken[1], 'Segunda frase aquí.');
      await coordinator.stop();
      expect(coordinator.playing, isFalse);
    });

    test('libro vacío no arranca', () async {
      coordinator.load(LocalBook(
        id: 'v',
        title: 'v',
        languageCode: 'es_ES',
        paragraphs: const [],
        sentences: const [],
      ));
      await coordinator.playFrom(0);
      expect(coordinator.playing, isFalse);
      expect(driver.spoken, isEmpty);
    });
  });
}
