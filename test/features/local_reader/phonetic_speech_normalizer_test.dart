import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/services/phonetic_speech_normalizer.dart';

void main() {
  group('PhoneticSpeechNormalizer', () {
    final plain = PhoneticSpeechNormalizer(const {});

    test('siglas con puntos se deletrean', () {
      expect(plain.normalize('La O.N.U. aprobó', 'es_ES'), 'La O N U aprobó');
    });

    test('símbolos en español', () {
      expect(plain.normalize('50% de 10€', 'es_ES'), '50 por ciento de 10 euros');
      expect(plain.normalize('A & B = C', 'es_ES'), 'A y B igual a C');
      expect(plain.normalize('2 + 2', 'es_ES'), '2 más 2');
    });

    test('símbolos en inglés y "+" no se toca en C++', () {
      expect(plain.normalize(r'$5 and 5%', 'en_US'), '5 dollars and 5 percent');
      expect(plain.normalize('I use C++', 'en_US'), 'I use C++');
    });

    test('idioma desconocido cae a inglés', () {
      expect(plain.normalize('10%', 'xx_XX'), '10 percent');
    });

    test('URL y markdown desaparecen', () {
      expect(plain.normalize('Ver https://ejemplo.com ya', 'es_ES'), 'Ver ya');
      expect(plain.normalize('**Hola** `mundo` [link](pagina)', 'es_ES'),
          'Hola mundo link');
      expect(plain.normalize('## Título', 'es_ES'), 'Título');
      expect(plain.normalize('> cita', 'es_ES'), 'cita');
    });

    test('reglas de pronunciación sin distinguir mayúsculas y por palabra', () {
      final n = PhoneticSpeechNormalizer(const {'Sapere': 'sápere', ' x ': ''});
      expect(n.rules, {'sapere': 'sápere'});
      expect(n.normalize('SAPERE es sapere, no sapereX', 'es_ES'),
          'sápere es sápere, no sapereX');
    });

    test('mapToOriginal devuelve offsets del texto original', () {
      final n = plain.normalizeWithMap('O.N.U. dijo', 'es_ES');
      expect(n.text, 'O N U dijo');
      expect(n.changed, isTrue);
      final dijoNormalized = n.text.indexOf('dijo');
      expect(n.mapToOriginal(dijoNormalized), 'O.N.U. dijo'.indexOf('dijo'));
      expect(n.mapToOriginal(0), 0);
      expect(n.mapToOriginal(-1), 0);
      expect(n.mapToOriginal(999), n.original.length);
    });

    test('mapToOriginal con inserciones largas (símbolo → palabra)', () {
      final original = '50% hoy';
      final n = plain.normalizeWithMap(original, 'es_ES');
      expect(n.text, '50 por ciento hoy');
      expect(n.mapToOriginal(n.text.indexOf('hoy')), original.indexOf('hoy'));
    });

    test('texto sin cambios', () {
      final n = plain.normalizeWithMap('Hola mundo', 'es_ES');
      expect(n.changed, isFalse);
      expect(n.mapToOriginal(5), 5);
    });
  });
}
