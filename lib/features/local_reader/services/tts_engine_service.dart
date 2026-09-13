import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/local_voice.dart';
import 'tts_locale_map.dart';

class TtsProgress {
  final int start;
  final int end;
  final String word;

  const TtsProgress({required this.start, required this.end, required this.word});

  @override
  String toString() => 'TtsProgress($start-$end "$word")';
}

abstract class TtsDriver {
  Future<List<LocalVoice>> voices();
  Future<void> setVoice(LocalVoice v);
  Future<void> setLanguage(String ttsLocale);

  /// Velocidad en escala del motor (flutter_tts: 0–1, 0.5 = normal).
  Future<void> setRate(double r);
  Future<void> setPitch(double p);
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
  Stream<TtsProgress> get progress;
  Stream<void> get completed;
  Future<void> dispose();
}

class SystemTtsDriver implements TtsDriver {
  final FlutterTts _tts;
  final _progress = StreamController<TtsProgress>.broadcast();
  final _completed = StreamController<void>.broadcast();
  bool _configured = false;

  SystemTtsDriver({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      _tts.setProgressHandler((text, start, end, word) {
        _progress.add(TtsProgress(start: start, end: end, word: word));
      });
      _tts.setCompletionHandler(() => _completed.add(null));
      _tts.setCancelHandler(() => _completed.add(null));
      _tts.setErrorHandler((msg) {
        debugPrint('[SystemTtsDriver] error: $msg');
        _completed.add(null);
      });
    } catch (e) {
      debugPrint('[SystemTtsDriver] configure failed: $e');
    }
  }

  @override
  Future<List<LocalVoice>> voices() async {
    await _ensureConfigured();
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      final out = <LocalVoice>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        final locale = item['locale']?.toString() ?? '';
        if (name.isEmpty || locale.isEmpty) continue;
        out.add(LocalVoice.fromEngine(
          name: name,
          locale: locale,
          gender: item['gender']?.toString(),
        ));
      }
      return out;
    } catch (e) {
      debugPrint('[SystemTtsDriver] getVoices failed: $e');
      return const [];
    }
  }

  @override
  Future<void> setVoice(LocalVoice v) async {
    await _ensureConfigured();
    try {
      await _tts.setVoice({'name': v.name, 'locale': v.locale});
    } catch (e) {
      debugPrint('[SystemTtsDriver] setVoice failed: $e');
    }
  }

  @override
  Future<void> setLanguage(String ttsLocale) async {
    await _ensureConfigured();
    try {
      await _tts.setLanguage(ttsLocale);
    } catch (e) {
      debugPrint('[SystemTtsDriver] setLanguage failed: $e');
    }
  }

  @override
  Future<void> setRate(double r) async {
    await _ensureConfigured();
    try {
      await _tts.setSpeechRate(r);
    } catch (e) {
      debugPrint('[SystemTtsDriver] setSpeechRate failed: $e');
    }
  }

  @override
  Future<void> setPitch(double p) async {
    await _ensureConfigured();
    try {
      await _tts.setPitch(p);
    } catch (e) {
      debugPrint('[SystemTtsDriver] setPitch failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    await _ensureConfigured();
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[SystemTtsDriver] speak failed: $e');
      _completed.add(null);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[SystemTtsDriver] stop failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('[SystemTtsDriver] pause failed: $e');
    }
  }

  @override
  Stream<TtsProgress> get progress => _progress.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async {
    await stop();
    await _progress.close();
    await _completed.close();
  }
}

class TtsEngineService {
  final TtsDriver driver;

  /// Velocidad de usuario 0.5–2.0 (1.0 = normal).
  double _rate = 1.0;
  double _pitch = 1.0;
  LocalVoice? _voice;
  List<LocalVoice>? _cache;

  TtsEngineService({TtsDriver? driver}) : driver = driver ?? SystemTtsDriver();

  double get rate => _rate;
  double get pitch => _pitch;
  LocalVoice? get voice => _voice;
  Stream<TtsProgress> get progress => driver.progress;
  Stream<void> get completed => driver.completed;

  /// 0.5–2.0 del usuario → 0–1 del motor (1.0 → 0.5).
  static double engineRateOf(double userRate) =>
      (userRate.clamp(0.5, 2.0) / 2.0).clamp(0.0, 1.0);

  Future<List<LocalVoice>> allVoices({bool refresh = false}) async {
    if (_cache != null && !refresh) return _cache!;
    try {
      _cache = await driver.voices();
    } catch (e) {
      debugPrint('[TtsEngineService] voices failed: $e');
      _cache = const [];
    }
    return _cache!;
  }

  /// Voces para el locale de la app: primero región exacta, luego mismo
  /// idioma; dentro de cada grupo las neurales primero.
  Future<List<LocalVoice>> voicesFor(String appLocale) async {
    final all = await allVoices();
    if (all.isEmpty) return const [];
    final target = ttsLocaleOf(appLocale).toLowerCase();
    final lang = ttsLanguageOf(appLocale);
    final exact = <LocalVoice>[];
    final sameLang = <LocalVoice>[];
    for (final v in all) {
      final loc = v.locale.toLowerCase().replaceAll('_', '-');
      if (loc == target) {
        exact.add(v);
      } else if (v.language == lang) {
        sameLang.add(v);
      }
    }
    int neuralFirst(LocalVoice a, LocalVoice b) {
      if (a.isNeural != b.isNeural) return a.isNeural ? -1 : 1;
      return a.name.compareTo(b.name);
    }
    exact.sort(neuralFirst);
    sameLang.sort(neuralFirst);
    return [...exact, ...sameLang];
  }

  /// Para español la primera; para el resto la última neural si hay, si no la última.
  LocalVoice? pickDefault(List<LocalVoice> voices, String appLocale) {
    if (voices.isEmpty) return null;
    if (ttsLanguageOf(appLocale) == 'es') return voices.first;
    final neural = voices.where((v) => v.isNeural).toList();
    if (neural.isNotEmpty) return neural.last;
    return voices.last;
  }

  Future<void> setVoice(LocalVoice v) async {
    _voice = v;
    try {
      await driver.setLanguage(v.locale);
      await driver.setVoice(v);
    } catch (e) {
      debugPrint('[TtsEngineService] setVoice failed: $e');
    }
  }

  Future<void> setLanguage(String appLocale) async {
    try {
      await driver.setLanguage(ttsLocaleOf(appLocale));
    } catch (e) {
      debugPrint('[TtsEngineService] setLanguage failed: $e');
    }
  }

  Future<void> setRate(double userRate) async {
    _rate = userRate.clamp(0.5, 2.0);
    try {
      await driver.setRate(engineRateOf(_rate));
    } catch (e) {
      debugPrint('[TtsEngineService] setRate failed: $e');
    }
  }

  Future<void> setPitch(double p) async {
    _pitch = p.clamp(0.5, 2.0);
    try {
      await driver.setPitch(_pitch);
    } catch (e) {
      debugPrint('[TtsEngineService] setPitch failed: $e');
    }
  }

  Future<void> speakSentence(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await driver.speak(text);
    } catch (e) {
      debugPrint('[TtsEngineService] speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await driver.stop();
    } catch (e) {
      debugPrint('[TtsEngineService] stop failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      await driver.pause();
    } catch (e) {
      debugPrint('[TtsEngineService] pause failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await driver.dispose();
    } catch (e) {
      debugPrint('[TtsEngineService] dispose failed: $e');
    }
  }
}
