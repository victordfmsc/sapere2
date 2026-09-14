import 'package:flutter_test/flutter_test.dart';
import 'package:sapere/langauges/langauges.dart';

/// Claves de portada, Mis creaciones e Historial. Si una falta en un idioma,
/// GetX pintaría la clave en crudo ("trendingNow") o, con fallbackLocale,
/// el texto en inglés: cada idioma debe tener la suya.
void main() {
  const List<String> requiredKeys = <String>[
    'trendingNow',
    'popularOnSapere',
    'play',
    'info',
    'beginYourLegacy',
    'emptyCreationsSubtitle',
    'createFirstSapere',
    'loading',
    'history',
    'historyTitle',
    'historySubtitle',
    'recentActivity',
    'noHistoryYet',
    'historyAudio',
    'historyReading',
    'audio',
    'book',
    'refundInProgress',
  ];

  final Map<String, Map<String, String>> keys = TransLanguage().keys;

  test('la app declara 29 idiomas', () {
    expect(keys.length, 29);
  });

  for (final String locale in keys.keys) {
    test('$locale tiene las claves de portada, creaciones e historial', () {
      final List<String> missing =
          requiredKeys.where((k) => !keys[locale]!.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'faltan en $locale: $missing');
    });
  }
}
