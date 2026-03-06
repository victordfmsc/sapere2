import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Rx;
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/models/learning_models.dart';
import 'package:sapere/providers/learning_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:sapere/models/media.dart';
import 'package:sapere/providers/history_provider.dart';
import '../../../../main.dart'; // audioHandler
import '../../../../core/constant/images.dart'; // AppBgAudios
import 'components/avatar_glow.dart';
import 'package:sapere/widgets/sapere_image.dart';

class AudioPlayerScreen extends StatefulWidget {
  final BukBukPost post;
  final Duration? initialPosition;

  const AudioPlayerScreen({
    super.key,
    required this.post,
    this.initialPosition,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AudioPlayer _bgPlayer;
  String? _currentBgAudio;
  double _bgVolume = 0.2;
  StreamSubscription? _playbackStateSubscription;
  Timer? _progressSaveTimer;

  @override
  void initState() {
    super.initState();
    _bgPlayer = AudioPlayer();
    _bgPlayer.setAsset(AppBgAudios.audioFire);
    _bgPlayer.setLoopMode(LoopMode.one);
    _bgPlayer.setVolume(_bgVolume);
    _currentBgAudio = AppBgAudios.audioFire;

    _playbackStateSubscription = audioHandler.playbackState.listen((
      state,
    ) async {
      final isPlaying = state.playing;
      if (_currentBgAudio != null) {
        if (isPlaying && !_bgPlayer.playing) {
          await _bgPlayer.play();
        } else if (!isPlaying && _bgPlayer.playing) {
          await _bgPlayer.pause();
        }
      }

      if (state.processingState == AudioProcessingState.completed &&
          widget.post.postId != null) {
        _triggerAutoCardGeneration();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentItem = audioHandler.mediaItem.value;
      if (currentItem == null || currentItem.id != widget.post.sapereUrl) {
        await loadAndPlay(
          widget.post.sapereUrl ?? '',
          widget.post.sapereName ?? 'Sapere',
          initialPosition: widget.initialPosition,
        );
      }
    });

    // Save progress every 5 seconds
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    final state = audioHandler.playbackState.value;
    final mediaItem = audioHandler.mediaItem.value;
    if (mediaItem != null &&
        mediaItem.id == widget.post.sapereUrl &&
        state.processingState != AudioProcessingState.idle) {
      final historyProvider = Provider.of<HistoryProvider>(
        context,
        listen: false,
      );
      await historyProvider.saveAudioProgress(
        widget.post,
        state.position,
        mediaItem.duration ?? Duration.zero,
      );
    }
  }

  Future<void> loadAndPlay(
    String url,
    String title, {
    Duration? initialPosition,
  }) async {
    try {
      final tempPlayer = AudioPlayer();
      final duration = await tempPlayer.setUrl(url);
      await tempPlayer.dispose();

      final mediaItem = MediaItem(
        id: url,
        title: title,
        duration: duration,
        artUri:
            widget.post.newCover != null
                ? Uri.parse(widget.post.newCover!)
                : null,
        artist: widget.post.gamificationSubject ?? "Sapere",
        extras: {
          'postId': widget.post.postId,
          'categoryNames': widget.post.sapereCategoryNames,
          'typeNames': widget.post.sapereTypeNames,
          'language': widget.post.language,
          'languageCode': widget.post.languageCode,
        },
      );
      await audioHandler.loadAndPlay(
        url,
        mediaItem,
        initialPosition: initialPosition,
      );
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  void _triggerAutoCardGeneration() {
    if (widget.post.postId != null) {
      Provider.of<LearningProvider>(
        context,
        listen: false,
      ).generateCardsForPost(widget.post);
    }
  }

  @override
  void dispose() {
    _saveProgress(); // Final save
    _progressSaveTimer?.cancel();
    _bgPlayer.dispose();
    _playbackStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> playBackgroundAudio(String assetPath) async {
    if (_currentBgAudio == assetPath) return;
    try {
      await _bgPlayer.setAsset(assetPath);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(_bgVolume);
      if (audioHandler.playbackState.value.playing) {
        await _bgPlayer.play();
      }
      setState(() => _currentBgAudio = assetPath);
    } catch (e) {
      print("Background audio error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // IMMERSIVE BACKGROUND
          Positioned.fill(
            child:
                widget.post.newCover != null
                    ? SapereImage(
                      imageUrl: widget.post.newCover!,
                      fit: BoxFit.cover,
                    )
                    : const SizedBox(),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      Text(
                        "nowPlaying".tr,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () => _showQuickNoteDialog(
                              context,
                              audioHandler.playbackState.value.position,
                            ),
                        icon: Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),

                  // COVER
                  SizedBox(height: 10.h),
                  CircularCoverWithWaveEffect(
                    cover: widget.post.newCover ?? "",
                  ),

                  // INFO
                  SizedBox(height: 20.h),
                  StreamBuilder<MediaItem?>(
                    stream: audioHandler.mediaItem,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.title ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontFamily: 'NotoSerifDisplay',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    widget.post.gamificationSubject?.toUpperCase() ??
                        "wisdomFragment".tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textColor.withOpacity(0.6),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // CONTROLS PANEL
                  _buildMainControlPanel(),
                  SizedBox(height: 20.h),

                  // ATMOSPHERE PANEL
                  _buildAtmospherePanel(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControlPanel() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          StreamBuilder<MediaState>(
            stream: _mediaStateStream,
            builder: (context, snapshot) {
              final mediaState = snapshot.data;
              final duration = mediaState?.mediaItem?.duration ?? Duration.zero;
              final position = mediaState?.position ?? Duration.zero;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      activeTrackColor: AppColors.textColor,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value:
                          position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                      onChanged: (v) {},
                      onChangeEnd:
                          (v) => audioHandler.seek(
                            Duration(milliseconds: v.round()),
                          ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 12.h),
          StreamBuilder<bool>(
            stream: audioHandler.playbackState.map((s) => s.playing).distinct(),
            builder: (context, snapshot) {
              final playing = snapshot.data ?? false;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _speedButton(),
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => audioHandler.skipToPrevious(),
                  ),
                  _playPauseButton(playing),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => audioHandler.skipToNext(),
                  ),
                  const Icon(
                    Icons.share_outlined,
                    color: Colors.white38,
                    size: 24,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _playPauseButton(bool playing) {
    return GestureDetector(
      onTap: () => playing ? audioHandler.pause() : audioHandler.play(),
      child: Container(
        height: 64.w,
        width: 64.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.black,
          size: 36,
        ),
      ),
    );
  }

  Widget _speedButton() {
    return StreamBuilder<double>(
      stream: audioHandler.playbackState.map((s) => s.speed).distinct(),
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return InkWell(
          onTap: () {
            double next = speed == 1.0 ? 1.5 : (speed == 1.5 ? 0.75 : 1.0);
            audioHandler.setSpeed(next);
          },
          child: Text(
            "${speed}x",
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAtmospherePanel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "atmosphere".tr,
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _bgAudioBtn(AppBgAudios.audioFire, AppBgAudios.audioFireIcon),
                  SizedBox(width: 8.w),
                  _bgAudioBtn(
                    AppBgAudios.audioWater,
                    AppBgAudios.audioWaterIcon,
                  ),
                  SizedBox(width: 8.w),
                  _bgAudioBtn(AppBgAudios.audioRain, AppBgAudios.audioRainIcon),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Icon(Icons.volume_down, size: 14.sp, color: Colors.white24),
              SizedBox(
                width: 100.w,
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: _bgVolume,
                  activeColor: Colors.white30,
                  inactiveColor: Colors.white10,
                  onChanged: (v) {
                    setState(() => _bgVolume = v);
                    _bgPlayer.setVolume(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bgAudioBtn(String path, String icon) {
    final active = _currentBgAudio == path;
    return GestureDetector(
      onTap: () => playBackgroundAudio(path),
      child: Container(
        height: 36.w,
        width: 36.w,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: active ? AppColors.textColor : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Image.asset(icon, color: active ? Colors.black : Colors.white54),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Stream<MediaState> get _mediaStateStream =>
      rx.Rx.combineLatest2<MediaItem?, Duration, MediaState>(
        audioHandler.mediaItem,
        AudioService.position,
        (mediaItem, position) => MediaState(mediaItem, position),
      );

  Future<void> _showQuickNoteDialog(
    BuildContext context,
    Duration currentPosition,
  ) async {
    final TextEditingController noteController = TextEditingController();
    NoteType selectedType = NoteType.insight;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xff1C1C1E),
                  title: Text(
                    "newAnnotation".tr,
                    style: TextStyle(color: Colors.white, fontSize: 18.sp),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${'capturedAt'.tr} ${_formatDuration(currentPosition)}",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: noteController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "learnedHint".tr,
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: Colors.white10,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Wrap(
                        spacing: 8.w,
                        children:
                            NoteType.values.map((type) {
                              final isSelected = selectedType == type;
                              return ChoiceChip(
                                label: Text(
                                  _getNoteTypeName(type),
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primaryColor,
                                backgroundColor: Colors.white10,
                                onSelected: (val) {
                                  if (val)
                                    setDialogState(() => selectedType = type);
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("cancel".tr),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (noteController.text.isNotEmpty &&
                            widget.post.postId != null) {
                          Provider.of<LearningProvider>(
                            context,
                            listen: false,
                          ).addNote(
                            postId: widget.post.postId!,
                            postTitle: widget.post.sapereName ?? 'Sapere',
                            content: noteController.text,
                            type: selectedType,
                            timestampMs: currentPosition.inMilliseconds,
                          );
                          Navigator.pop(context);
                          Get.snackbar(
                            "noteSaved".tr,
                            "xpEarned".tr,
                            backgroundColor: AppColors.primaryColor,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: Text(
                        "save".tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.insight:
        return "idea".tr;
      case NoteType.keyData:
        return "data".tr;
      case NoteType.question:
        return "question".tr;
      case NoteType.connection:
        return "connection".tr;
    }
  }
}
