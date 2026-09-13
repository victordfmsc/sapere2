/// Texto normalizado para el TTS junto con el mapa de offsets hacia el
/// texto original (para que el resaltado de palabras no se descuadre).
class NormalizedSentence {
  final String text;
  final String original;
  final List<int> _map;

  const NormalizedSentence._(this.text, this.original, this._map);

  /// Offset en el texto original para un offset del texto normalizado.
  int mapToOriginal(int normalizedOffset) {
    if (normalizedOffset < 0) return 0;
    if (normalizedOffset >= _map.length) return original.length;
    return _map[normalizedOffset];
  }

  bool get changed => text != original;
}

class _Mapped {
  String text;
  List<int> map;
  _Mapped(this.text, this.map);

  void replaceAll(RegExp regex, String Function(Match m) replacer) {
    final buf = StringBuffer();
    final newMap = <int>[];
    var last = 0;
    for (final m in regex.allMatches(text)) {
      for (var i = last; i < m.start; i++) {
        buf.write(text[i]);
        newMap.add(map[i]);
      }
      final rep = replacer(m);
      final anchor = map.isEmpty ? 0 : map[m.start < map.length ? m.start : map.length - 1];
      for (var i = 0; i < rep.length; i++) {
        buf.write(rep[i]);
        newMap.add(anchor);
      }
      last = m.end;
    }
    for (var i = last; i < text.length; i++) {
      buf.write(text[i]);
      newMap.add(map[i]);
    }
    text = buf.toString();
    map = newMap;
  }
}

class PhoneticSpeechNormalizer {
  /// palabra (sin distinguir mayúsculas) → pronunciación.
  final Map<String, String> rules;

  PhoneticSpeechNormalizer(Map<String, String> rules)
      : rules = rules.map((k, v) => MapEntry(k.trim().toLowerCase(), v.trim()))
          ..removeWhere((k, v) => k.isEmpty || v.isEmpty);

  static const _symbols = <String, Map<String, String>>{
    'es': {'&': 'y', '%': 'por ciento', '€': 'euros', r'$': 'dólares', '+': 'más', '=': 'igual a', '→': 'flecha'},
    'en': {'&': 'and', '%': 'percent', '€': 'euros', r'$': 'dollars', '+': 'plus', '=': 'equals', '→': 'arrow'},
    'fr': {'&': 'et', '%': 'pour cent', '€': 'euros', r'$': 'dollars', '+': 'plus', '=': 'égale', '→': 'flèche'},
    'de': {'&': 'und', '%': 'Prozent', '€': 'Euro', r'$': 'Dollar', '+': 'plus', '=': 'gleich', '→': 'Pfeil'},
    'pt': {'&': 'e', '%': 'por cento', '€': 'euros', r'$': 'dólares', '+': 'mais', '=': 'igual a', '→': 'seta'},
    'it': {'&': 'e', '%': 'per cento', '€': 'euro', r'$': 'dollari', '+': 'più', '=': 'uguale a', '→': 'freccia'},
  };

  static final _url = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);
  static final _mdLink = RegExp(r'\[([^\]]+)\]\([^)]*\)');
  static final _mdEmphasis = RegExp(r'(\*{1,3}|_{2,3})(.+?)\1');
  static final _mdCode = RegExp(r'`([^`]*)`');
  static final _mdHeading = RegExp(r'^\s*#{1,6}\s+');
  static final _mdQuote = RegExp(r'^\s*>\s?');
  static final _acronym = RegExp(r'(?:\p{Lu}\.){2,}', unicode: true);
  static final _number = r'\d[\d.,]*';
  static final _multiSpace = RegExp(r'\s{2,}');
  static final _leading = RegExp(r'^\s+');
  static final _trailing = RegExp(r'\s+$');

  String normalize(String sentence, String languageCode) =>
      normalizeWithMap(sentence, languageCode).text;

  NormalizedSentence normalizeWithMap(String sentence, String languageCode) {
    final m = _Mapped(sentence, List<int>.generate(sentence.length, (i) => i));

    m.replaceAll(_url, (_) => '');
    m.replaceAll(_mdLink, (x) => x.group(1)!);
    m.replaceAll(_mdCode, (x) => x.group(1)!);
    m.replaceAll(_mdEmphasis, (x) => x.group(2)!);
    m.replaceAll(_mdHeading, (_) => '');
    m.replaceAll(_mdQuote, (_) => '');

    for (final rule in rules.entries) {
      final key = RegExp.escape(rule.key);
      m.replaceAll(
        RegExp('(?<![\\p{L}\\p{N}])$key(?![\\p{L}\\p{N}])',
            unicode: true, caseSensitive: false),
        (_) => rule.value,
      );
    }

    m.replaceAll(_acronym, (x) {
      final letters = x.group(0)!.replaceAll('.', '');
      return letters.split('').join(' ');
    });

    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    final table = _symbols[lang] ?? _symbols['en']!;
    final currency = ['€', r'$'];
    for (final sym in currency) {
      final word = table[sym]!;
      final esc = RegExp.escape(sym);
      m.replaceAll(RegExp('$esc\\s*($_number)'), (x) => '${x.group(1)} $word');
      m.replaceAll(RegExp('($_number)\\s*$esc'), (x) => '${x.group(1)} $word');
      m.replaceAll(RegExp(esc), (_) => ' $word ');
    }
    m.replaceAll(RegExp('($_number)\\s*%'), (x) => '${x.group(1)} ${table['%']}');
    m.replaceAll(RegExp('%'), (_) => ' ${table['%']} ');
    for (final sym in ['&', '=', '→']) {
      m.replaceAll(RegExp(RegExp.escape(sym)), (_) => ' ${table[sym]} ');
    }
    // "+" solo cuando actúa como operador (entre números/espacios), no en "C++".
    m.replaceAll(RegExp(r'(?<=[\d\s])\+(?=[\d\s])'), (_) => ' ${table['+']} ');

    m.replaceAll(_multiSpace, (_) => ' ');
    m.replaceAll(_leading, (_) => '');
    m.replaceAll(_trailing, (_) => '');

    return NormalizedSentence._(m.text, sentence, m.map);
  }
}
