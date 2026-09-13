class ReaderSettings {
  static const fontFamilies = ['Charter', 'CharisSILR', 'Poppins', 'DMSans'];
  static const themes = ['paper', 'sepia', 'night', 'contrast'];
  static const maskLineOptions = [0, 1, 3, 5];

  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double horizontalMargin;
  final String theme;
  final bool focusMode;
  final int maskLines;
  final double rate;
  final double ambientVolume;
  final String? ambientTrackId;
  final bool sfxEnabled;
  final bool autoScroll;

  /// appLocale (xx_YY) → LocalVoice.id
  final Map<String, String> voiceByLanguage;

  const ReaderSettings({
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.horizontalMargin,
    required this.theme,
    required this.focusMode,
    required this.maskLines,
    required this.rate,
    required this.ambientVolume,
    this.ambientTrackId,
    required this.sfxEnabled,
    required this.autoScroll,
    required this.voiceByLanguage,
  });

  factory ReaderSettings.defaults() => const ReaderSettings(
        fontFamily: 'Charter',
        fontSize: 18,
        lineHeight: 1.6,
        horizontalMargin: 20,
        theme: 'paper',
        focusMode: false,
        maskLines: 0,
        rate: 1.0,
        ambientVolume: 0.6,
        ambientTrackId: null,
        sfxEnabled: false,
        autoScroll: true,
        voiceByLanguage: {},
      );

  ReaderSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? horizontalMargin,
    String? theme,
    bool? focusMode,
    int? maskLines,
    double? rate,
    double? ambientVolume,
    String? ambientTrackId,
    bool clearAmbientTrack = false,
    bool? sfxEnabled,
    bool? autoScroll,
    Map<String, String>? voiceByLanguage,
  }) {
    return ReaderSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      theme: theme ?? this.theme,
      focusMode: focusMode ?? this.focusMode,
      maskLines: maskLines ?? this.maskLines,
      rate: rate ?? this.rate,
      ambientVolume: ambientVolume ?? this.ambientVolume,
      ambientTrackId:
          clearAmbientTrack ? null : (ambientTrackId ?? this.ambientTrackId),
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      autoScroll: autoScroll ?? this.autoScroll,
      voiceByLanguage:
          voiceByLanguage ?? Map<String, String>.from(this.voiceByLanguage),
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'horizontalMargin': horizontalMargin,
        'theme': theme,
        'focusMode': focusMode,
        'maskLines': maskLines,
        'rate': rate,
        'ambientVolume': ambientVolume,
        'ambientTrackId': ambientTrackId,
        'sfxEnabled': sfxEnabled,
        'autoScroll': autoScroll,
        'voiceByLanguage': voiceByLanguage,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    final d = ReaderSettings.defaults();
    return ReaderSettings(
      fontFamily: json['fontFamily'] as String? ?? d.fontFamily,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? d.fontSize,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? d.lineHeight,
      horizontalMargin:
          (json['horizontalMargin'] as num?)?.toDouble() ?? d.horizontalMargin,
      theme: json['theme'] as String? ?? d.theme,
      focusMode: json['focusMode'] as bool? ?? d.focusMode,
      maskLines: json['maskLines'] as int? ?? d.maskLines,
      rate: (json['rate'] as num?)?.toDouble() ?? d.rate,
      ambientVolume:
          (json['ambientVolume'] as num?)?.toDouble() ?? d.ambientVolume,
      ambientTrackId: json['ambientTrackId'] as String?,
      sfxEnabled: json['sfxEnabled'] as bool? ?? d.sfxEnabled,
      autoScroll: json['autoScroll'] as bool? ?? d.autoScroll,
      voiceByLanguage: (json['voiceByLanguage'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
    );
  }
}
