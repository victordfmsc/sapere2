import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/local_book.dart';
import '../../models/local_voice.dart';
import '../../models/reader_settings.dart';
import '../../services/background_audio_service.dart';
import '../../services/bimodal_sync_coordinator.dart';
import '../../services/contextual_ambient_service.dart';
import '../../services/local_library_service.dart';
import '../../services/sfx_keyword_service.dart';
import '../../services/tts_engine_service.dart';

/// Estado reactivo del lector bimodal: expone el coordinador de sincronía a la
/// UI (GetX), persiste progreso y ajustes, y gestiona voces, ambiente y SFX.
class LocalReaderController extends GetxController {
  final BimodalSyncCoordinator coordinator;
  final LocalLibraryService libraryService;
  final TtsEngineService ttsEngine;
  final BackgroundAudioService? ambient;
  final SfxKeywordService? sfx;
  final ContextualAmbientService contextualAmbient;

  final Rx<LocalBook?> book = Rx<LocalBook?>(null);
  final RxInt currentSentence = 0.obs;
  final RxnInt currentWord = RxnInt();
  final RxBool isPlaying = false.obs;
  final Rx<ReaderSettings> settings = ReaderSettings.defaults().obs;
  final RxList<LocalVoice> availableVoices = <LocalVoice>[].obs;
  final Rxn<LocalVoice> selectedVoice = Rxn<LocalVoice>();

  /// Marca "continuar desde aquí": visible hasta que el usuario pulsa play,
  /// toca una oración o navega con siguiente/anterior.
  final RxBool showResumeMarker = false.obs;
  final RxBool voicesLoading = false.obs;

  /// Pista ambiente que suena ahora (null = ninguna).
  final RxnString ambientTrackId = RxnString();

  static const _saveDebounce = Duration(seconds: 1);

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _saveTimer;
  bool _progressDirty = false;

  LocalReaderController({
    required this.coordinator,
    required this.libraryService,
    required this.ttsEngine,
    this.ambient,
    this.sfx,
    ContextualAmbientService? contextualAmbient,
  }) : contextualAmbient = contextualAmbient ?? ContextualAmbientService() {
    _subs.add(coordinator.currentSentence.listen(_onSentence));
    _subs.add(coordinator.currentWord.listen((w) => currentWord.value = w));
    _subs.add(coordinator.isPlaying.listen((p) => isPlaying.value = p));
    _subs.add(coordinator.finished.listen((_) => saveProgressNow()));
  }

  // ---------------------------------------------------------------- apertura

  Future<void> openBook(LocalBook b, {bool autoApplyAmbient = false}) async {
    if (coordinator.playing) await coordinator.stop();
    await saveProgressNow();

    book.value = b;
    settings.value = await libraryService.getSettings();
    coordinator.load(b);
    currentSentence.value = coordinator.sentenceIndex;
    currentWord.value = null;
    showResumeMarker.value = b.progressSentence > 0 && b.sentences.isNotEmpty;

    await ttsEngine.setRate(settings.value.rate);
    await _loadVoices(b);
    if (sfx != null) await sfx!.loadAssetIndex();

    if (autoApplyAmbient && ambient != null) {
      final id = settings.value.ambientTrackId ??
          contextualAmbient.suggestTrackId(_sampleText(b), b.languageCode);
      await _applyAmbient(id);
    }
  }

  Future<void> _loadVoices(LocalBook b) async {
    voicesLoading.value = true;
    try {
      final voices = await ttsEngine.voicesFor(b.languageCode);
      availableVoices.assignAll(voices);
      final chosen = _voiceById(voices, b.preferredVoiceId) ??
          _voiceById(voices, settings.value.voiceByLanguage[b.languageCode]) ??
          ttsEngine.pickDefault(voices, b.languageCode);
      selectedVoice.value = chosen;
      if (chosen != null) {
        await ttsEngine.setVoice(chosen);
      } else {
        await ttsEngine.setLanguage(b.languageCode);
      }
    } finally {
      voicesLoading.value = false;
    }
  }

  LocalVoice? _voiceById(List<LocalVoice> voices, String? id) {
    if (id == null) return null;
    for (final v in voices) {
      if (v.id == id) return v;
    }
    return null;
  }

  String _sampleText(LocalBook b) {
    final buf = StringBuffer();
    for (final p in b.paragraphs) {
      buf.write(p);
      buf.write(' ');
      if (buf.length > 3000) break;
    }
    return buf.toString();
  }

  // -------------------------------------------------------------- transporte

  Future<void> play() async {
    showResumeMarker.value = false;
    if (!coordinator.playing) await coordinator.resume();
    _syncFromCoordinator();
  }

  Future<void> pause() async {
    await coordinator.pause();
    _syncFromCoordinator();
  }

  Future<void> togglePlay() => coordinator.playing ? pause() : play();

  Future<void> next() async {
    showResumeMarker.value = false;
    await coordinator.next();
    _syncFromCoordinator();
  }

  Future<void> previous() async {
    showResumeMarker.value = false;
    await coordinator.previous();
    _syncFromCoordinator();
  }

  Future<void> jumpTo(int sentenceIndex) async {
    showResumeMarker.value = false;
    await coordinator.seek(sentenceIndex);
    _syncFromCoordinator();
  }

  /// Los streams del coordinador llegan una microtarea después; tras una
  /// acción del usuario reflejamos el estado al instante.
  void _syncFromCoordinator() {
    isPlaying.value = coordinator.playing;
    _onSentence(coordinator.sentenceIndex);
  }

  Future<void> setRate(double rate) async {
    await ttsEngine.setRate(rate);
    await updateSettings((s) => s.copyWith(rate: ttsEngine.rate));
  }

  // -------------------------------------------------------------------- voces

  Future<void> selectVoice(LocalVoice v) async {
    final b = book.value;
    selectedVoice.value = v;
    await ttsEngine.setVoice(v);
    if (b == null) return;
    await updateSettings((s) => s.copyWith(
          voiceByLanguage: {...s.voiceByLanguage, b.languageCode: v.id},
        ));
    b.preferredVoiceId = v.id;
    book.refresh();
    await libraryService.saveBook(b);
  }

  Future<void> previewVoice(LocalVoice v) async {
    if (coordinator.playing) await coordinator.pause();
    final lang = book.value?.languageCode ?? v.locale;
    await ttsEngine.setVoice(v);
    await ttsEngine.speakSentence(_previewPhrase(lang));
    final current = selectedVoice.value;
    if (current != null && current != v) await ttsEngine.setVoice(current);
  }

  static String _previewPhrase(String languageCode) {
    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    switch (lang) {
      case 'es':
        return 'Hola, así sonará la lectura de tu libro.';
      case 'fr':
        return 'Bonjour, voici comment sonnera la lecture de votre livre.';
      case 'de':
        return 'Hallo, so wird das Vorlesen deines Buches klingen.';
      case 'pt':
        return 'Olá, é assim que soará a leitura do seu livro.';
      case 'it':
        return 'Ciao, ecco come suonerà la lettura del tuo libro.';
      default:
        return 'Hello, this is how your book will sound.';
    }
  }

  // ----------------------------------------------------------------- ambiente

  Future<void> setAmbient(String? trackId) async {
    await updateSettings((s) => trackId == null
        ? s.copyWith(clearAmbientTrack: true)
        : s.copyWith(ambientTrackId: trackId));
    await _applyAmbient(trackId);
  }

  Future<void> setAmbientVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await updateSettings((s) => s.copyWith(ambientVolume: v));
    await ambient?.setVolume(v);
  }

  Future<void> _applyAmbient(String? trackId) async {
    final player = ambient;
    if (player == null) return;
    final track = ambientTrackById(trackId);
    if (track == null) {
      await player.stop();
      ambientTrackId.value = null;
      return;
    }
    await player.play(track.asset, volume: settings.value.ambientVolume);
    ambientTrackId.value = track.id;
  }

  // ------------------------------------------------------------------ ajustes

  Future<void> updateSettings(
      ReaderSettings Function(ReaderSettings) change) async {
    settings.value = change(settings.value);
    await libraryService.saveSettings(settings.value);
  }

  // ----------------------------------------------------------------- progreso

  void _onSentence(int index) {
    final changed = currentSentence.value != index;
    currentSentence.value = index;
    final b = book.value;
    if (b == null) return;
    if (b.progressSentence != index) {
      b.progressSentence = index;
      _progressDirty = true;
      _scheduleSave();
    }
    if (changed) _maybePlaySfx(b, index);
  }

  void _maybePlaySfx(LocalBook b, int index) {
    final fx = sfx;
    if (fx == null || !fx.hasAssets || !settings.value.sfxEnabled) return;
    if (!coordinator.playing) return;
    if (index < 0 || index >= b.sentences.length) return;
    unawaited(fx.playForSentence(b.sentences[index].text, b.languageCode));
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(saveProgressNow()));
  }

  /// Guarda el progreso pendiente sin esperar al debounce (p. ej. al salir).
  Future<void> saveProgressNow() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final b = book.value;
    if (b == null || !_progressDirty) return;
    _progressDirty = false;
    try {
      await libraryService.saveBook(b);
    } catch (e) {
      debugPrint('[LocalReaderController] saveBook failed: $e');
    }
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    unawaited(saveProgressNow());
    super.onClose();
  }
}
