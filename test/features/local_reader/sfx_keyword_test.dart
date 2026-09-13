import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/services/sfx_keyword_service.dart';

void main() {
  final service = SfxKeywordService();

  group('SfxKeywordService.detect', () {
    test('español: varios efectos en una oración, en orden de catálogo', () {
      final ids = service.detect('El trueno retumbó bajo la lluvia y la puerta se cerró.', 'es_ES');
      expect(ids, ['thunder', 'rain', 'door']);
    });

    test('inglés con mayúsculas', () {
      expect(service.detect('The WOLF howled at the BELLS.', 'en_US'), ['bell', 'wolf']);
    });

    test('palabras clave multi-palabra (francés "coup de feu")', () {
      expect(service.detect('Un coup de feu retentit.', 'fr_FR'), contains('gunshot'));
    });

    test('coincide por palabra completa', () {
      expect(service.detect('El marido y la puertaX.', 'es_ES'), isEmpty);
    });

    test('idioma sin diccionario usa el inglés', () {
      expect(service.detect('The rain fell.', 'ru_RU'), ['rain']);
    });

    test('vacío y sin coincidencias', () {
      expect(service.detect('', 'es_ES'), isEmpty);
      expect(service.detect('Una tarde cualquiera.', 'es_ES'), isEmpty);
    });

    test('hasAssets es false antes de cargar el índice', () {
      expect(service.hasAssets, isFalse);
    });

    test('catálogo: cada efecto tiene asset y claves en inglés', () {
      for (final fx in sfxCatalog) {
        expect(fx.asset, 'assets/audio/sfx/${fx.id}.mp3');
        expect(fx.keywords['en'], isNotEmpty);
      }
    });
  });
}
