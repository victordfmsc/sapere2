import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/services/text_tokenizer_service.dart';

void main() {
  final tokenizer = TextTokenizerService();

  List<String> texts(String paragraph) => tokenizer
      .splitSentences(paragraph, paragraphIndex: 0, startIndex: 0)
      .map((s) => s.text)
      .toList();

  group('TextTokenizerService', () {
    test('español: "Sr." y "3.5" no cierran oración; ¿? y ¡! sí', () {
      final result = texts(
        'El Sr. García compró 3.5 kilos. Luego se fue a casa. ¿Volverá? ¡Sí!',
      );
      expect(result, [
        'El Sr. García compró 3.5 kilos.',
        'Luego se fue a casa.',
        '¿Volverá?',
        '¡Sí!',
      ]);
    });

    test('español: palabras con offsets correctos', () {
      final s = tokenizer
          .splitSentences('El Sr. García compró 3.5 kilos.',
              paragraphIndex: 0, startIndex: 0)
          .single;
      final words = s.words.map((w) => w.text).toList();
      expect(words, containsAll(['El', 'Sr', 'García', 'compró', 'kilos']));
      for (final w in s.words) {
        expect(s.text.substring(w.start, w.end), w.text);
      }
      expect(s.wordIndexAt(s.text.indexOf('García')), 2);
    });

    test('inglés: abreviaturas Mr./St. y cierre con ! ?', () {
      final result = texts(
        'Mr. Jones arrived at St. Louis. It was late! Was it?',
      );
      expect(result, [
        'Mr. Jones arrived at St. Louis.',
        'It was late!',
        'Was it?',
      ]);
    });

    test('inglés: punto seguido de minúscula no cierra', () {
      expect(texts('He said yes. and left. Then silence.'), [
        'He said yes. and left.',
        'Then silence.',
      ]);
    });

    test('chino: 。 cierra sin espacio y tokeniza por carácter', () {
      final sentences = tokenizer.splitSentences('今天天气很好。我们去公园。',
          paragraphIndex: 0, startIndex: 0);
      expect(sentences.map((s) => s.text).toList(), ['今天天气很好。', '我们去公园。']);
      expect(tokenizer.isCjk(sentences.first.text), isTrue);
      expect(sentences.first.words.map((w) => w.text).toList(),
          ['今', '天', '天', '气', '很', '好']);
    });

    test('árabe: divide por punto y tokeniza palabras', () {
      final sentences = tokenizer.splitSentences(
          'ذهب الولد إلى المدرسة. ثم عاد إلى البيت.',
          paragraphIndex: 0,
          startIndex: 0);
      expect(sentences.length, 2);
      expect(sentences.first.text, 'ذهب الولد إلى المدرسة.');
      expect(sentences.first.words.length, 4);
      expect(sentences.last.words.map((w) => w.text).toList(),
          ['ثم', 'عاد', 'إلى', 'البيت']);
    });

    test('splitParagraphs numera oraciones globalmente', () {
      final all = tokenizer.splitParagraphs(['Uno. Dos.', 'Tres.']);
      expect(all.map((s) => s.indexInBook).toList(), [0, 1, 2]);
      expect(all.map((s) => s.paragraphIndex).toList(), [0, 0, 1]);
    });

    test('puntos suspensivos y cierre de comillas quedan en la oración', () {
      expect(texts('Dijo "hola..." Y se fue.'), ['Dijo "hola..."', 'Y se fue.']);
    });
  });
}
