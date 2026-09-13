import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/local_book.dart';
import '../models/text_segment.dart';
import 'phonetic_speech_normalizer.dart';
import 'tts_engine_service.dart';

/// Sincroniza la lectura en voz alta (oración a oración) con el resaltado
/// de la oración y la palabra actuales.
///
/// Los cambios de voz o velocidad hechos en [TtsEngineService] se aplican
/// en la siguiente oración; pausar y reanudar repite la oración en curso.
class BimodalSyncCoordinator {
  final TtsEngineService ttsEngine;
  final PhoneticSpeechNormalizer normalizer;
  final Duration latency;

  final _sentence = BehaviorSubject<int>.seeded(0);
  final _word = BehaviorSubject<int?>.seeded(null);
  final _playing = BehaviorSubject<bool>.seeded(false);
  final _finished = PublishSubject<void>();

  LocalBook? _book;
  int _generation = 0;
  NormalizedSentence? _currentNormalized;
  TextSentence? _currentSentence;
  StreamSubscription<TtsProgress>? _progressSub;

  BimodalSyncCoordinator({
    required this.ttsEngine,
    PhoneticSpeechNormalizer? normalizer,
    this.latency = Duration.zero,
  }) : normalizer = normalizer ?? PhoneticSpeechNormalizer(const {}) {
    _progressSub = ttsEngine.progress.listen(_onProgress);
  }

  Stream<int> get currentSentence => _sentence.stream;
  Stream<int?> get currentWord => _word.stream;
  Stream<bool> get isPlaying => _playing.stream;
  Stream<void> get finished => _finished.stream;

  int get sentenceIndex => _sentence.value;
  bool get playing => _playing.value;
  LocalBook? get book => _book;

  void load(LocalBook book) {
    _generation++;
    _book = book;
    _playing.add(false);
    _word.add(null);
    _sentence.add(book.progressSentence.clamp(0, _lastIndex(book)));
  }

  int _lastIndex(LocalBook book) =>
      book.sentences.isEmpty ? 0 : book.sentences.length - 1;

  Future<void> playFrom(int sentenceIndex) async {
    final book = _book;
    if (book == null || book.sentences.isEmpty) return;
    final gen = ++_generation;
    await ttsEngine.stop();
    if (gen != _generation) return;
    _sentence.add(sentenceIndex.clamp(0, _lastIndex(book)));
    _word.add(null);
    _playing.add(true);
    unawaited(_runLoop(gen));
  }

  Future<void> pause() async {
    if (!_playing.value) return;
    _generation++;
    _playing.add(false);
    _word.add(null);
    await ttsEngine.stop();
  }

  Future<void> resume() async {
    if (_playing.value) return;
    await playFrom(_sentence.value);
  }

  Future<void> stop() async {
    _generation++;
    _playing.add(false);
    _word.add(null);
    await ttsEngine.stop();
  }

  Future<void> next() => seek(_sentence.value + 1);

  Future<void> previous() => seek(_sentence.value - 1);

  /// Salta a [index]: si está reproduciendo, arranca ahí; si no, solo mueve el resaltado.
  Future<void> seek(int index) async {
    final book = _book;
    if (book == null || book.sentences.isEmpty) return;
    final target = index.clamp(0, _lastIndex(book));
    if (_playing.value) {
      await playFrom(target);
    } else {
      _sentence.add(target);
      _word.add(null);
    }
  }

  Future<void> _runLoop(int gen) async {
    final book = _book!;
    while (gen == _generation && _playing.value) {
      final index = _sentence.value;
      if (index >= book.sentences.length) break;
      final sentence = book.sentences[index];
      final normalized = normalizer.normalizeWithMap(sentence.text, book.languageCode);
      _currentSentence = sentence;
      _currentNormalized = normalized;
      _word.add(null);

      await _speakAndWait(normalized.text, gen);
      if (gen != _generation || !_playing.value) return;

      if (index + 1 >= book.sentences.length) {
        _playing.add(false);
        _word.add(null);
        _finished.add(null);
        return;
      }
      _sentence.add(index + 1);
    }
  }

  Future<void> _speakAndWait(String text, int gen) async {
    if (text.trim().isEmpty) return;
    final done = Completer<void>();
    final sub = ttsEngine.completed.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await ttsEngine.speakSentence(text);
      if (gen != _generation) return;
      if (!done.isCompleted) await done.future;
    } catch (e) {
      debugPrint('[BimodalSyncCoordinator] speak failed: $e');
    } finally {
      await sub.cancel();
    }
  }

  void _onProgress(TtsProgress p) {
    final sentence = _currentSentence;
    final normalized = _currentNormalized;
    if (sentence == null || normalized == null || !_playing.value) return;
    final original = normalized.mapToOriginal(p.start);
    final index = _wordIndexFor(sentence, original);
    if (latency == Duration.zero) {
      _word.add(index);
    } else {
      final gen = _generation;
      Future.delayed(latency, () {
        if (gen == _generation && _playing.value) _word.add(index);
      });
    }
  }

  int? _wordIndexFor(TextSentence sentence, int offset) {
    final direct = sentence.wordIndexAt(offset);
    if (direct != null) return direct;
    int? last;
    for (var i = 0; i < sentence.words.length; i++) {
      if (sentence.words[i].start <= offset) last = i;
    }
    return last;
  }

  void dispose() {
    _generation++;
    _progressSub?.cancel();
    _sentence.close();
    _word.close();
    _playing.close();
    _finished.close();
  }
}
