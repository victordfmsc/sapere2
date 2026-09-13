import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/models/local_book.dart';
import 'package:sapere/features/local_reader/models/reader_settings.dart';
import 'package:sapere/features/local_reader/services/local_library_service.dart';
import 'package:sapere/features/local_reader/services/text_tokenizer_service.dart';

LocalBook _book(String id, {int progress = 0}) {
  final paragraphs = ['Hola mundo. Adiós.'];
  return LocalBook(
    id: id,
    title: 'Libro $id',
    languageCode: 'es_ES',
    paragraphs: paragraphs,
    sentences: TextTokenizerService().splitParagraphs(paragraphs),
    progressSentence: progress,
  );
}

void main() {
  late Directory tmp;
  late LocalLibraryService lib;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('local_reader_test_');
    lib = await LocalLibraryService.createAt(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('LocalLibraryService', () {
    test('createAt crea root y books/', () async {
      expect(lib.root.path, tmp.path);
      expect(await Directory('${tmp.path}${Platform.pathSeparator}books').exists(), isTrue);
    });

    test('saveBook / getBook / getBooks / deleteBook', () async {
      expect(await lib.getBooks(), isEmpty);
      expect(await lib.getBook('nope'), isNull);

      await lib.saveBook(_book('a', progress: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await lib.saveBook(_book('b/con:raros', progress: 0));

      final a = await lib.getBook('a');
      expect(a, isNotNull);
      expect(a!.title, 'Libro a');
      expect(a.progressSentence, 1);
      expect(a.sentences.length, 2);
      expect(a.sentences.first.words.first.text, 'Hola');

      final all = await lib.getBooks();
      expect(all.map((b) => b.id).toList(), ['b/con:raros', 'a'],
          reason: 'ordenados por updatedAt descendente');

      await lib.deleteBook('a');
      expect(await lib.getBook('a'), isNull);
      expect((await lib.getBooks()).length, 1);
    });

    test('saveBook actualiza el progreso existente', () async {
      final b = _book('p');
      await lib.saveBook(b);
      b.progressSentence = 1;
      await lib.saveBook(b);
      expect((await lib.getBook('p'))!.progressSentence, 1);
    });

    test('settings: defaults si no hay fichero y roundtrip', () async {
      final d = await lib.getSettings();
      expect(d.fontFamily, ReaderSettings.defaults().fontFamily);
      expect(d.voiceByLanguage, isEmpty);

      final s = d.copyWith(
        rate: 1.5,
        theme: 'night',
        ambientTrackId: 'rain',
        sfxEnabled: true,
        voiceByLanguage: {'es_ES': 'voz|es-ES'},
      );
      await lib.saveSettings(s);
      final back = await lib.getSettings();
      expect(back.rate, 1.5);
      expect(back.theme, 'night');
      expect(back.ambientTrackId, 'rain');
      expect(back.sfxEnabled, isTrue);
      expect(back.voiceByLanguage, {'es_ES': 'voz|es-ES'});

      await lib.saveSettings(back.copyWith(clearAmbientTrack: true));
      expect((await lib.getSettings()).ambientTrackId, isNull);
    });

    test('reglas de pronunciación', () async {
      expect(await lib.getPronunciationRules(), isEmpty);
      await lib.savePronunciationRules({'sapere': 'sápere'});
      expect(await lib.getPronunciationRules(), {'sapere': 'sápere'});
    });

    test('fichero corrupto no rompe getBooks', () async {
      await lib.saveBook(_book('ok'));
      await File('${tmp.path}${Platform.pathSeparator}books${Platform.pathSeparator}bad.json')
          .writeAsString('{no es json');
      final all = await lib.getBooks();
      expect(all.map((b) => b.id).toList(), ['ok']);
    });
  });
}
