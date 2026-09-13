import 'package:flutter/material.dart';

/// Colores del lector según `ReaderSettings.theme`.
class ReaderPalette {
  final Color background;
  final Color text;
  final Color surface;
  final Color sentenceHighlight;
  final Color wordHighlight;
  final Color wordText;
  final Color accent;
  final Brightness brightness;

  const ReaderPalette({
    required this.background,
    required this.text,
    required this.surface,
    required this.sentenceHighlight,
    required this.wordHighlight,
    required this.wordText,
    required this.accent,
    required this.brightness,
  });

  static const paper = ReaderPalette(
    background: Color(0xFFF7F3EA),
    text: Color(0xFF1E1E1E),
    surface: Color(0xFFFFFDF8),
    sentenceHighlight: Color(0x38F1CC89),
    wordHighlight: Color(0xC8F1CC89),
    wordText: Color(0xFF1E1E1E),
    accent: Color(0xFFB08A3E),
    brightness: Brightness.light,
  );

  static const sepia = ReaderPalette(
    background: Color(0xFFF1E4CC),
    text: Color(0xFF4A3A25),
    surface: Color(0xFFF8EFDD),
    sentenceHighlight: Color(0x40C8A15A),
    wordHighlight: Color(0xB3C8A15A),
    wordText: Color(0xFF2E2213),
    accent: Color(0xFF8C6A32),
    brightness: Brightness.light,
  );

  static const night = ReaderPalette(
    background: Color(0xFF121212),
    text: Color(0xFFE8E8E8),
    surface: Color(0xFF1E1E1E),
    sentenceHighlight: Color(0x2EF1CC89),
    wordHighlight: Color(0xD9F1CC89),
    wordText: Color(0xFF121212),
    accent: Color(0xFFF1CC89),
    brightness: Brightness.dark,
  );

  static const contrast = ReaderPalette(
    background: Color(0xFF000000),
    text: Color(0xFFFFFFFF),
    surface: Color(0xFF111111),
    sentenceHighlight: Color(0x59FFFF00),
    wordHighlight: Color(0xFFFFFF00),
    wordText: Color(0xFF000000),
    accent: Color(0xFFFFFF00),
    brightness: Brightness.dark,
  );

  static ReaderPalette of(String theme) {
    switch (theme) {
      case 'sepia':
        return sepia;
      case 'night':
        return night;
      case 'contrast':
        return contrast;
      default:
        return paper;
    }
  }

  bool get isDark => brightness == Brightness.dark;
}
