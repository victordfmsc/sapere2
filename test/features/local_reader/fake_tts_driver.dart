import 'dart:async';

import 'package:sapere/features/local_reader/models/local_voice.dart';
import 'package:sapere/features/local_reader/services/tts_engine_service.dart';

/// Motor TTS sintético: emite un [TtsProgress] por palabra separado por
/// [wordDelay] y, como flutter_tts con `awaitSpeakCompletion(true)`,
/// `speak` no termina hasta que acaba la frase o se llama a `stop`.
class FakeTtsDriver implements TtsDriver {
  final List<LocalVoice> voiceList;
  final Duration wordDelay;

  final _progress = StreamController<TtsProgress>.broadcast();
  final _completed = StreamController<void>.broadcast();

  final List<String> spoken = [];
  LocalVoice? voice;
  String? language;
  double? rate;
  double? pitch;
  int stopCalls = 0;

  int _gen = 0;
  Completer<void>? _current;

  FakeTtsDriver({
    this.voiceList = const [],
    this.wordDelay = const Duration(milliseconds: 5),
  });

  @override
  Future<List<LocalVoice>> voices() async => voiceList;

  @override
  Future<void> setVoice(LocalVoice v) async => voice = v;

  @override
  Future<void> setLanguage(String ttsLocale) async => language = ttsLocale;

  @override
  Future<void> setRate(double r) async => rate = r;

  @override
  Future<void> setPitch(double p) async => pitch = p;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    final gen = ++_gen;
    final done = Completer<void>();
    _current = done;
    unawaited(_emit(text, gen, done));
    await done.future;
  }

  Future<void> _emit(String text, int gen, Completer<void> done) async {
    for (final m in RegExp(r'\S+').allMatches(text)) {
      await Future<void>.delayed(wordDelay);
      if (gen != _gen) return;
      _progress.add(TtsProgress(start: m.start, end: m.end, word: m.group(0)!));
    }
    await Future<void>.delayed(wordDelay);
    if (gen != _gen) return;
    if (!_completed.isClosed) _completed.add(null);
    if (!done.isCompleted) done.complete();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _gen++;
    final c = _current;
    if (c != null && !c.isCompleted) {
      c.complete();
      if (!_completed.isClosed) _completed.add(null);
    }
    _current = null;
  }

  @override
  Future<void> pause() => stop();

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

/// Espera hasta que [condition] sea cierta o venza [timeout].
Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  Duration step = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('waitFor: condición no cumplida en $timeout');
    }
    await Future<void>.delayed(step);
  }
}
