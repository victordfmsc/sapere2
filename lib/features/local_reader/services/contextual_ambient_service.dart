/// Sugiere una pista ambiente ('rain', 'fire', 'water') según el texto.
class ContextualAmbientService {
  static const _keywords = <String, Map<String, List<String>>>{
    'rain': {
      'es': ['lluvia', 'llovía', 'llover', 'lloviendo', 'tormenta', 'chubasco', 'diluvio', 'gotas', 'truenos', 'relámpago'],
      'en': ['rain', 'raining', 'rained', 'storm', 'thunderstorm', 'downpour', 'drizzle', 'thunder', 'lightning'],
      'fr': ['pluie', 'pleuvait', 'pleuvoir', 'orage', 'tempête', 'averse', 'tonnerre'],
      'de': ['regen', 'regnete', 'regnet', 'gewitter', 'sturm', 'schauer', 'donner'],
      'pt': ['chuva', 'chovia', 'chover', 'tempestade', 'temporal', 'aguaceiro', 'trovão'],
      'it': ['pioggia', 'pioveva', 'piovere', 'temporale', 'tempesta', 'acquazzone', 'tuono'],
    },
    'fire': {
      'es': ['fuego', 'hogar', 'chimenea', 'hoguera', 'llamas', 'brasas', 'volcán', 'incendio', 'fogata'],
      'en': ['fire', 'hearth', 'fireplace', 'bonfire', 'flames', 'embers', 'volcano', 'campfire', 'blaze'],
      'fr': ['feu', 'foyer', 'cheminée', 'flammes', 'braises', 'volcan', 'incendie'],
      'de': ['feuer', 'kamin', 'herd', 'flammen', 'glut', 'vulkan', 'lagerfeuer', 'brand'],
      'pt': ['fogo', 'lareira', 'fogueira', 'chamas', 'brasas', 'vulcão', 'incêndio'],
      'it': ['fuoco', 'camino', 'focolare', 'falò', 'fiamme', 'braci', 'vulcano', 'incendio'],
    },
    'water': {
      'es': ['mar', 'río', 'océano', 'agua', 'olas', 'playa', 'arroyo', 'cascada', 'lago', 'orilla'],
      'en': ['sea', 'river', 'ocean', 'water', 'waves', 'beach', 'stream', 'waterfall', 'lake', 'shore', 'tide'],
      'fr': ['mer', 'rivière', 'fleuve', 'océan', 'eau', 'vagues', 'plage', 'ruisseau', 'cascade', 'lac'],
      'de': ['meer', 'fluss', 'ozean', 'wasser', 'wellen', 'strand', 'bach', 'wasserfall', 'see', 'ufer'],
      'pt': ['mar', 'rio', 'oceano', 'água', 'ondas', 'praia', 'riacho', 'cascata', 'lago', 'margem'],
      'it': ['mare', 'fiume', 'oceano', 'acqua', 'onde', 'spiaggia', 'ruscello', 'cascata', 'lago', 'riva'],
    },
  };

  static final _wordRegex = RegExp(r'\p{L}+', unicode: true);

  String? suggestTrackId(String text, String languageCode) {
    if (text.trim().isEmpty) return null;
    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    final words = _wordRegex
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toSet();
    String? best;
    var bestScore = 0;
    for (final entry in _keywords.entries) {
      final list = entry.value[lang] ?? entry.value['en']!;
      var score = 0;
      for (final k in list) {
        if (words.contains(k)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }
    return bestScore == 0 ? null : best;
  }
}
