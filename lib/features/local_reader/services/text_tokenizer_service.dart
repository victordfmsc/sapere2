import '../models/text_segment.dart';

/// Divide texto en oraciones y palabras conservando offsets.
class TextTokenizerService {
  static const _terminators = {'.', '!', '?', '…', '。', '！', '？'};
  static const _cjkTerminators = {'。', '！', '？'};
  static const _closers = {'"', '”', '»', ')', ']', '\'', '’', '」', '』', '）'};

  /// Abreviaturas (sin punto, minúsculas) tras las que un punto NO cierra oración.
  static const _abbreviations = {
    // Español
    'sr', 'sra', 'srta', 'sres', 'dr', 'dra', 'dres', 'd', 'dña', 'ud', 'uds',
    'vd', 'vds', 'etc', 'p', 'ej', 'pág', 'págs', 'pag', 'pags', 'núm', 'num',
    'art', 'cap', 'av', 'avda', 'tel', 'aprox', 'dpto', 'fig', 'vol', 'lic',
    'ing', 'prof', 'gral', 'cía', 'cia', 'ca', 'cf', 'ss', 'a', 'm',
    // Inglés
    'mr', 'mrs', 'ms', 'st', 'vs', 'inc', 'ltd', 'jr', 'no', 'co',
    'corp', 'dept', 'est', 'gen', 'gov', 'hon', 'ie', 'eg', 'i', 'e', 'u',
    'rev', 'sgt', 'capt', 'col', 'lt', 'ave', 'blvd', 'rd', 'mt',
    // Francés / alemán / portugués / italiano
    'mme', 'mlle', 'ex', 'bzw', 'usw', 'ggf', 'evtl', 'z', 'b', 'nr', 'str',
    'exmo', 'exma', 'sig', 'sigg', 'dott', 'ecc', 'pp',
  };

  static final RegExp _cjkChar = RegExp(
    r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}ー]',
    unicode: true,
  );

  static final RegExp _wordRegex = RegExp(
    r"[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*",
    unicode: true,
  );

  static final RegExp _cjkWordRegex = RegExp(
    r"[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}ー]"
    r"|(?:(?![\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}ー])[\p{L}\p{M}\p{N}])+",
    unicode: true,
  );

  static final RegExp _lowerStart = RegExp(r'^\p{Ll}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{N}', unicode: true);

  bool isCjk(String text) => _cjkChar.hasMatch(text);

  List<TextSentence> splitParagraphs(List<String> paragraphs) {
    final result = <TextSentence>[];
    var index = 0;
    for (var p = 0; p < paragraphs.length; p++) {
      final sentences = splitSentences(
        paragraphs[p],
        paragraphIndex: p,
        startIndex: index,
      );
      result.addAll(sentences);
      index += sentences.length;
    }
    return result;
  }

  List<TextSentence> splitSentences(
    String paragraph, {
    required int paragraphIndex,
    required int startIndex,
  }) {
    final sentences = <TextSentence>[];
    final ranges = _sentenceRanges(paragraph);
    for (final range in ranges) {
      final raw = paragraph.substring(range.$1, range.$2);
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      sentences.add(TextSentence(
        text: trimmed,
        paragraphIndex: paragraphIndex,
        indexInBook: startIndex + sentences.length,
        words: tokenizeWords(trimmed, cjk: isCjk(trimmed)),
      ));
    }
    return sentences;
  }

  List<TextWordToken> tokenizeWords(String sentence, {required bool cjk}) {
    final regex = cjk ? _cjkWordRegex : _wordRegex;
    return regex
        .allMatches(sentence)
        .map((m) => TextWordToken(text: m.group(0)!, start: m.start, end: m.end))
        .toList();
  }

  List<(int, int)> _sentenceRanges(String text) {
    final ranges = <(int, int)>[];
    var start = 0;
    var i = 0;
    final n = text.length;
    while (i < n) {
      final ch = text[i];
      if (!_terminators.contains(ch)) {
        i++;
        continue;
      }
      if (ch == '.' && _isAbbreviationOrDecimal(text, i)) {
        i++;
        continue;
      }
      // Agrupa terminadores consecutivos (?!, ..., ¡!) y cierres.
      var end = i + 1;
      while (end < n && (_terminators.contains(text[end]) || text[end] == '.')) {
        end++;
      }
      while (end < n && _closers.contains(text[end])) {
        end++;
      }
      final isCjkEnd = _cjkTerminators.contains(ch);
      final atEnd = end >= n;
      final followedBySpace = !atEnd && _isWhitespace(text[end]);
      if (atEnd || followedBySpace || isCjkEnd) {
        final rest = text.substring(end).trimLeft();
        if (!isCjkEnd && ch == '.' && rest.isNotEmpty && _lowerStart.hasMatch(rest)) {
          i = end;
          continue;
        }
        ranges.add((start, end));
        start = end;
      }
      i = end;
    }
    if (start < n) ranges.add((start, n));
    return ranges;
  }

  bool _isAbbreviationOrDecimal(String text, int dot) {
    final prev = dot > 0 ? text[dot - 1] : '';
    final next = dot + 1 < text.length ? text[dot + 1] : '';
    if (prev.isNotEmpty && next.isNotEmpty && _digit.hasMatch(prev) && _digit.hasMatch(next)) {
      return true;
    }
    var s = dot;
    while (s > 0 && !_isWhitespace(text[s - 1]) && text[s - 1] != '.') {
      s--;
    }
    final word = text.substring(s, dot).toLowerCase();
    if (word.isEmpty) return false;
    if (word.length == 1 && RegExp(r'\p{L}', unicode: true).hasMatch(word)) {
      return true;
    }
    return _abbreviations.contains(word);
  }

  bool _isWhitespace(String ch) => ch.trim().isEmpty;
}
