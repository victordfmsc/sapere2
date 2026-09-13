import 'text_segment.dart';

class LocalBook {
  String id;
  String title;

  /// Código de idioma de la app (xx_YY), p. ej. `es_ES`.
  String languageCode;
  String? coverPath;
  List<String> paragraphs;
  List<TextSentence> sentences;
  int progressSentence;
  String? preferredVoiceId;
  DateTime updatedAt;

  LocalBook({
    required this.id,
    required this.title,
    required this.languageCode,
    this.coverPath,
    required this.paragraphs,
    required this.sentences,
    this.progressSentence = 0,
    this.preferredVoiceId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Progreso 0.0–1.0 según la oración actual.
  double get progress {
    if (sentences.isEmpty) return 0;
    return (progressSentence / sentences.length).clamp(0.0, 1.0);
  }

  LocalBook copyWith({
    String? id,
    String? title,
    String? languageCode,
    String? coverPath,
    List<String>? paragraphs,
    List<TextSentence>? sentences,
    int? progressSentence,
    String? preferredVoiceId,
    DateTime? updatedAt,
  }) {
    return LocalBook(
      id: id ?? this.id,
      title: title ?? this.title,
      languageCode: languageCode ?? this.languageCode,
      coverPath: coverPath ?? this.coverPath,
      paragraphs: paragraphs ?? List<String>.from(this.paragraphs),
      sentences: sentences ?? List<TextSentence>.from(this.sentences),
      progressSentence: progressSentence ?? this.progressSentence,
      preferredVoiceId: preferredVoiceId ?? this.preferredVoiceId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'languageCode': languageCode,
        'coverPath': coverPath,
        'paragraphs': paragraphs,
        'sentences': sentences.map((s) => s.toJson()).toList(),
        'progressSentence': progressSentence,
        'preferredVoiceId': preferredVoiceId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalBook.fromJson(Map<String, dynamic> json) => LocalBook(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        languageCode: json['languageCode'] as String? ?? 'en_US',
        coverPath: json['coverPath'] as String?,
        paragraphs: (json['paragraphs'] as List<dynamic>? ?? const [])
            .map((p) => p as String)
            .toList(),
        sentences: (json['sentences'] as List<dynamic>? ?? const [])
            .map((s) => TextSentence.fromJson(s as Map<String, dynamic>))
            .toList(),
        progressSentence: json['progressSentence'] as int? ?? 0,
        preferredVoiceId: json['preferredVoiceId'] as String?,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
