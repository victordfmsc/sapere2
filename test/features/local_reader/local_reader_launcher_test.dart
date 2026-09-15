import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/local_reader_launcher.dart';
import 'package:sapere/features/local_reader/models/local_book.dart';
import 'package:sapere/features/local_reader/services/local_library_service.dart';

void main() {
  late Directory tmp;
  late LocalLibraryService library;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('local_reader_launcher_test_');
    library = await LocalLibraryService.createAt(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<LocalBook> abrir(String content, {String title = 'Constantinopla'}) {
    return prepareLocalBook(
      library: library,
      bookId: 'doc1',
      title: title,
      content: content,
      languageCode: 'es_ES',
    );
  }

  Future<void> leerHasta(int oracion, {String? voz}) async {
    final guardado = (await library.getBook('doc1'))!;
    guardado
      ..progressSentence = oracion
      ..preferredVoiceId = voz;
    await library.saveBook(guardado);
  }

  group('prepareLocalBook', () {
    test('llega una seccion nueva: sigue en la oracion leida y con su voz',
        () async {
      await abrir('Uno. Dos.\n\nTres.');
      await leerHasta(2, voz: 'voz-es');

      final book = await abrir('Uno. Dos.\n\nTres.\n\nCuatro. Cinco.');

      expect(book.sentences, hasLength(5));
      expect(book.progressSentence, 2);
      expect(book.preferredVoiceId, 'voz-es');
      expect((await library.getBook('doc1'))!.progressSentence, 2);
    });

    test('mismo texto: reutiliza el guardado y actualiza el titulo', () async {
      await abrir('Uno. Dos.', title: 'Tema');
      await leerHasta(1);

      final book = await abrir('Uno. Dos.', title: 'Constantinopla, 1453');

      expect(book.progressSentence, 1);
      expect(book.title, 'Constantinopla, 1453');
      expect((await library.getBook('doc1'))!.title, 'Constantinopla, 1453');
    });
  });
}
