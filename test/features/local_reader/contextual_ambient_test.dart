import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/features/local_reader/services/contextual_ambient_service.dart';

void main() {
  final service = ContextualAmbientService();

  group('ContextualAmbientService', () {
    test('español: lluvia → rain', () {
      expect(
        service.suggestTrackId('La lluvia caía y los truenos rugían en la tormenta.', 'es_ES'),
        'rain',
      );
    });

    test('inglés: fire gana cuando hay más coincidencias', () {
      expect(
        service.suggestTrackId('The fireplace crackled with flames and embers near the sea.', 'en_US'),
        'fire',
      );
    });

    test('agua en francés', () {
      expect(service.suggestTrackId('La mer et les vagues sur la plage.', 'fr_FR'), 'water');
    });

    test('idioma sin diccionario usa el inglés', () {
      expect(service.suggestTrackId('Rain and thunder all night.', 'sv_SE'), 'rain');
    });

    test('sin palabras clave devuelve null', () {
      expect(service.suggestTrackId('Una tarde cualquiera en la oficina.', 'es_ES'), isNull);
      expect(service.suggestTrackId('   ', 'es_ES'), isNull);
    });

    test('coincide por palabra completa, no por substring', () {
      expect(service.suggestTrackId('El marido llegó.', 'es_ES'), isNull);
    });
  });
}
