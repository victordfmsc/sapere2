class BookAnnotation {
  final String bookId;
  final int sentenceIndex;
  final String note;
  final DateTime createdAt;

  const BookAnnotation({
    required this.bookId,
    required this.sentenceIndex,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'sentenceIndex': sentenceIndex,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BookAnnotation.fromJson(Map<String, dynamic> json) => BookAnnotation(
        bookId: json['bookId'] as String,
        sentenceIndex: json['sentenceIndex'] as int,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
