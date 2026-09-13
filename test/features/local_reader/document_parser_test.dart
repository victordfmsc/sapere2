import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/services/document_parser_service.dart';

void main() {
  final parser = PlainTextDocumentParser();

  group('PlainTextDocumentParser', () {
    test('párrafos separados por líneas en blanco, con CRLF', () {
      final paragraphs = parser.splitParagraphs(
        'Primera línea\r\nsigue el párrafo.\r\n\r\nSegundo párrafo.\r\n\r\n\r\nTercero.',
      );
      expect(paragraphs, [
        'Primera línea sigue el párrafo.',
        'Segundo párrafo.',
        'Tercero.',
      ]);
    });

    test('sin líneas en blanco: cada salto es un párrafo', () {
      expect(parser.splitParagraphs('Uno.\nDos.\nTres.'), ['Uno.', 'Dos.', 'Tres.']);
      expect(parser.splitParagraphs('Uno.\nDos.\n  \nTres.'), ['Uno. Dos.', 'Tres.'],
          reason: 'una línea solo con espacios cuenta como línea en blanco');
    });

    test('colapsa espacios y tabuladores', () {
      expect(parser.splitParagraphs('a\t\tb   c'), ['a b c']);
    });

    test('parseString construye el libro con oraciones numeradas', () async {
      final book = await parser.parseString(
        content: 'Hola mundo. Adiós mundo.\n\nOtro párrafo.',
        title: 'Prueba',
        bookId: 'b1',
        languageCode: 'es_ES',
      );
      expect(book.id, 'b1');
      expect(book.title, 'Prueba');
      expect(book.languageCode, 'es_ES');
      expect(book.paragraphs.length, 2);
      expect(book.sentences.map((s) => s.text).toList(),
          ['Hola mundo.', 'Adiós mundo.', 'Otro párrafo.']);
      expect(book.sentences.map((s) => s.paragraphIndex).toList(), [0, 0, 1]);
      expect(book.sentences.map((s) => s.indexInBook).toList(), [0, 1, 2]);
      expect(book.progressSentence, 0);
      expect(book.progress, 0);
    });

    test('el libro sobrevive a un ciclo JSON', () async {
      final book = await parser.parseString(
        content: 'Hola. Adiós.',
        title: 'T',
        bookId: 'b2',
        languageCode: 'en_US',
      );
      final copy = book.copyWith(progressSentence: 1);
      final json = copy.toJson();
      final back = book.copyWith();
      expect(back.sentences.length, 2);
      expect(json['progressSentence'], 1);
      expect(json['sentences'], hasLength(2));
    });
  });
}
