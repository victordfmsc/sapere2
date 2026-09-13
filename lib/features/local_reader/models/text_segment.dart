class TextWordToken {
  final String text;

  /// Offset inicial dentro de la oración (inclusive).
  final int start;

  /// Offset final dentro de la oración (exclusive).
  final int end;

  const TextWordToken({
    required this.text,
    required this.start,
    required this.end,
  });

  bool contains(int offset) => offset >= start && offset < end;

  Map<String, dynamic> toJson() => {'text': text, 'start': start, 'end': end};

  factory TextWordToken.fromJson(Map<String, dynamic> json) => TextWordToken(
        text: json['text'] as String,
        start: json['start'] as int,
        end: json['end'] as int,
      );

  @override
  String toString() => 'TextWordToken($text, $start-$end)';
}

class TextSentence {
  final String text;
  final int paragraphIndex;

  /// Índice global de la oración dentro del libro.
  final int indexInBook;
  final List<TextWordToken> words;

  const TextSentence({
    required this.text,
    required this.paragraphIndex,
    required this.indexInBook,
    required this.words,
  });

  /// Índice del token cuyo rango contiene [offset], o null.
  int? wordIndexAt(int offset) {
    for (var i = 0; i < words.length; i++) {
      if (words[i].contains(offset)) return i;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'paragraphIndex': paragraphIndex,
        'indexInBook': indexInBook,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory TextSentence.fromJson(Map<String, dynamic> json) => TextSentence(
        text: json['text'] as String,
        paragraphIndex: json['paragraphIndex'] as int,
        indexInBook: json['indexInBook'] as int,
        words: (json['words'] as List<dynamic>? ?? const [])
            .map((w) => TextWordToken.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() => 'TextSentence(#$indexInBook, "$text")';
}
