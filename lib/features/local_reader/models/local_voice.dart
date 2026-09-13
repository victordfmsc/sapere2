class LocalVoice {
  /// `name|locale`, estable entre sesiones.
  final String id;
  final String name;

  /// Locale del motor TTS, p. ej. `es-ES`.
  final String locale;
  final String? gender;

  /// El nombre contiene network/neural/enhanced/premium.
  final bool isNeural;

  const LocalVoice({
    required this.id,
    required this.name,
    required this.locale,
    this.gender,
    required this.isNeural,
  });

  factory LocalVoice.fromEngine({
    required String name,
    required String locale,
    String? gender,
  }) {
    final lower = name.toLowerCase();
    final neural = lower.contains('network') ||
        lower.contains('neural') ||
        lower.contains('enhanced') ||
        lower.contains('premium');
    return LocalVoice(
      id: '$name|$locale',
      name: name,
      locale: locale,
      gender: gender,
      isNeural: neural,
    );
  }

  /// Idioma sin región, en minúsculas: `es-ES` → `es`.
  String get language {
    final sep = locale.indexOf(RegExp('[-_]'));
    return (sep == -1 ? locale : locale.substring(0, sep)).toLowerCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'locale': locale,
        'gender': gender,
        'isNeural': isNeural,
      };

  factory LocalVoice.fromJson(Map<String, dynamic> json) => LocalVoice(
        id: json['id'] as String,
        name: json['name'] as String,
        locale: json['locale'] as String,
        gender: json['gender'] as String?,
        isNeural: json['isNeural'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) => other is LocalVoice && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LocalVoice($id)';
}
