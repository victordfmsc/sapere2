import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _bgPlayer = AudioPlayer();
  String? _currentBgAudio;

  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Future<void> loadAndPlay(
    String audioUrl,
    MediaItem item, {
    Duration? initialPosition,
  }) async {
    try {
      mediaItem.add(item);

      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));

      if (initialPosition != null && initialPosition > Duration.zero) {
        await _player.seek(initialPosition);
      }

      await _player.play();

      if (_currentBgAudio != null) {
        await _bgPlayer.play();
      }
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  Future<void> playBackgroundAudio(
    String assetPath, {
    double volume = 0.2,
  }) async {
    if (_currentBgAudio == assetPath) {
      await _bgPlayer.stop();
      _currentBgAudio = null;
      return;
    }

    try {
      await _bgPlayer.setAsset(assetPath);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(volume);
      _currentBgAudio = assetPath;

      if (_player.playing) {
        await _bgPlayer.play();
      }
    } catch (e) {
      print("Error in playBackgroundAudio: $e");
    }
  }

  Future<void> setBackgroundVolume(double volume) async {
    await _bgPlayer.setVolume(volume);
  }

  Future<void> tenSecondsForward() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final duration = _player.duration;
    if (duration != null && newPosition > duration) {
      await _player.seek(duration);
    } else {
      await _player.seek(newPosition);
    }
  }

  Future<void> tenSecondsBackward() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  @override
  Future<void> play() async {
    await _player.play();
    if (_currentBgAudio != null) {
      await _bgPlayer.play();
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    if (_bgPlayer.playing) {
      await _bgPlayer.pause();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _bgPlayer.stop();
  }

  @override
  Future<void> skipToNext() => tenSecondsForward();

  @override
  Future<void> skipToPrevious() => tenSecondsBackward();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState:
          const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
