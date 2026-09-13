import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constant/images.dart';

class AmbientTrack {
  final String id;
  final String asset;
  final String icon;

  /// Clave de traducción del nombre.
  final String nameKey;

  const AmbientTrack({
    required this.id,
    required this.asset,
    required this.icon,
    required this.nameKey,
  });
}

const List<AmbientTrack> ambientTracks = [
  AmbientTrack(
    id: 'rain',
    asset: AppBgAudios.audioRain,
    icon: AppBgAudios.audioRainIcon,
    nameKey: 'ambientRain',
  ),
  AmbientTrack(
    id: 'fire',
    asset: AppBgAudios.audioFire,
    icon: AppBgAudios.audioFireIcon,
    nameKey: 'ambientFire',
  ),
  AmbientTrack(
    id: 'water',
    asset: AppBgAudios.audioWater,
    icon: AppBgAudios.audioWaterIcon,
    nameKey: 'ambientWater',
  ),
];

AmbientTrack? ambientTrackById(String? id) {
  if (id == null) return null;
  for (final t in ambientTracks) {
    if (t.id == id) return t;
  }
  return null;
}

/// Sonido ambiente en bucle que se mezcla con la voz TTS sin robarle el foco.
class BackgroundAudioService {
  AudioPlayer? _player;
  String? _currentAsset;
  bool _sessionConfigured = false;

  bool get isPlaying => _player?.playing ?? false;
  String? get currentAsset => _currentAsset;

  Future<void> _configureSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      debugPrint('[BackgroundAudioService] session config failed: $e');
    }
  }

  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
  }

  Future<void> play(String assetPath, {double volume = 0.6}) async {
    await _configureSession();
    try {
      final player = _ensurePlayer();
      if (_currentAsset != assetPath) {
        await player.stop();
        await player.setAudioSource(AudioSource.asset(assetPath));
        await player.setLoopMode(LoopMode.one);
        _currentAsset = assetPath;
      }
      await player.setVolume(volume.clamp(0.0, 1.0));
      if (!player.playing) {
        player.play();
      }
    } catch (e) {
      debugPrint('[BackgroundAudioService] play failed: $e');
      _currentAsset = null;
    }
  }

  Future<void> setVolume(double v) async {
    try {
      await _player?.setVolume(v.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('[BackgroundAudioService] setVolume failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[BackgroundAudioService] stop failed: $e');
    }
    _currentAsset = null;
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (e) {
      debugPrint('[BackgroundAudioService] dispose failed: $e');
    }
    _player = null;
  }
}
