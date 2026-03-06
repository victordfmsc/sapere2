import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/main.dart';
import 'package:sapere/models/gamification_models.dart';
import 'package:sapere/models/post.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sapere/providers/gamification_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sapere/views/dashboard/stream/audio_player/audio_player.dart';
import 'package:get/get.dart';
import 'package:sapere/widgets/sapere_image.dart';

class GamifiedLessonScreen extends StatefulWidget {
  final GamifiedSubject subject;
  final GamifiedEpisode episode;
  final BukBukPost? post;

  const GamifiedLessonScreen({
    super.key,
    required this.subject,
    required this.episode,
    this.post,
  });

  @override
  State<GamifiedLessonScreen> createState() => _GamifiedLessonScreenState();
}

class _GamifiedLessonScreenState extends State<GamifiedLessonScreen> {
  bool _isQuizTime = false;
  int _selectedQuizAnswer = -1;
  StreamSubscription? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _setupPlaybackListener();
  }

  void _setupPlaybackListener() {
    _playbackSubscription = audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.completed) {
        final currentMedia = audioHandler.mediaItem.value;
        if (currentMedia != null &&
            widget.post != null &&
            currentMedia.id == widget.post!.sapereUrl) {
          if (mounted && !_isQuizTime) {
            setState(() {
              _isQuizTime = true;
            });
            Get.snackbar(
              'journeyCompleted'.tr,
              'wisdomCheckDesc'.tr,
              backgroundColor: Colors.amber.withOpacity(0.8),
              colorText: Colors.black,
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0B),
      appBar: AppBar(
        title: Text(
          widget.episode.title,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSerifDisplay',
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: const Color(0xff0A0A0B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xff0A0A0B), const Color(0xff1A1A1C)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlassContainer(
                height: 250.h,
                child: Stack(
                  children: [
                    if (widget.post?.newCover != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Opacity(
                          opacity: 0.4,
                          child: SapereImage(
                            imageUrl: widget.post!.newCover!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlayButton(),
                          SizedBox(height: 16.h),
                          Text(
                            widget.post?.sapereUrl != null
                                ? "revealKnowledge".tr
                                : "materializing".tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                "${"wisdomScale".tr}: ${widget.episode.level}",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                widget.episode.description,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 40.h),
              if (!_isQuizTime) _buildLockedQuizHint() else _buildQuizSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.white.withOpacity(0.04), child: child),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        if (widget.post?.sapereUrl != null) {
          Get.to(() => AudioPlayerScreen(post: widget.post!));
        } else {
          Get.snackbar(
            'starting'.tr,
            'materializingWait'.tr,
            backgroundColor: Colors.black87,
            colorText: Colors.white70,
          );
        }
      },
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: AppColors.textColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.textColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 50.sp),
      ),
    );
  }

  Widget _buildLockedQuizHint() {
    return _buildGlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Icon(Icons.lock_open_outlined, color: Colors.white24, size: 40.sp),
            SizedBox(height: 16.h),
            Text(
              "lockedQuizDesc".tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    return _buildGlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Colors.amber,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  "wisdomCheckRite".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              "${'quizQuestion'.tr} [${widget.episode.title}]?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15.sp,
                fontFamily: 'NotoSerifDisplay',
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24.h),
            ...List.generate(3, (index) {
              List<String> mockAnswers = [
                "Estructuras Fundamentales",
                "Patrones de Comportamiento",
                "Evolución Histórica",
              ];
              bool isSelected = _selectedQuizAnswer == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedQuizAnswer = index),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.textColor.withOpacity(0.12)
                            : Colors.white.withOpacity(0.02),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.textColor
                              : Colors.white.withOpacity(0.08),
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.circle : Icons.circle_outlined,
                        color:
                            isSelected ? AppColors.textColor : Colors.white24,
                        size: 18.sp,
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        mockAnswers[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap:
                  _selectedQuizAnswer != -1
                      ? () => _completeEpisodeAndGrantXP()
                      : null,
              child: Opacity(
                opacity: _selectedQuizAnswer != -1 ? 1.0 : 0.4,
                child: Container(
                  width: double.infinity,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: AppColors.textColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      if (_selectedQuizAnswer != -1)
                        BoxShadow(
                          color: AppColors.textColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "finishRite".tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeEpisodeAndGrantXP() {
    final gamificationProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );

    String episodeId = '${widget.subject.name}_${widget.episode.episodeNumber}';
    gamificationProvider.completeEpisode(episodeId, widget.episode.xpBase);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xff1A1A1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            title: Text(
              "knowledgeAcquired".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 18.sp,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: AppColors.textColor,
                  size: 80.sp,
                ),
                SizedBox(height: 24.h),
                Text(
                  "${'youEarnedXP'.tr} +${widget.episode.xpBase} XP",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontFamily: 'NotoSerifDisplay',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.episode.badgeOnCompletion != null) ...[
                  SizedBox(height: 16.h),
                  Text(
                    "newRank".tr,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10.sp,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    widget.episode.badgeOnCompletion!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "backToMap".tr,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
