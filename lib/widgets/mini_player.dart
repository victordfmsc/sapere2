import 'dart:ui' as dart_ui;
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/main.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/views/dashboard/stream/audio_player/audio_player.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, playbackStateSnapshot) {
            final playbackState = playbackStateSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;
            final isIdle =
                playbackState?.processingState == AudioProcessingState.idle;

            if (isIdle) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () {
                // Navigate back to full player
                // We need the original BukBukPost.
                // We can reconstruct it from MediaItem extras if we populate them.
                final post = BukBukPost(
                  postId: mediaItem.extras?['postId'] as String?,
                  sapereName: mediaItem.title,
                  newCover: mediaItem.artUri?.toString(),
                  sapereUrl: mediaItem.id,
                  gamificationSubject: mediaItem.artist,
                );

                Get.to(() => AudioPlayerScreen(post: post));
              },
              child: Container(
                height: 70.h,
                margin: EdgeInsets.only(
                  left: 10.w,
                  right: 10.w,
                  top: 8.h,
                  bottom: 125.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: BackdropFilter(
                    filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Progress bar at the top
                          StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, positionSnapshot) {
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              final duration =
                                  mediaItem.duration ??
                                  const Duration(milliseconds: 1);
                              final progress = (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0);

                              return LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.kSamiOrange,
                                ),
                                minHeight: 2.5,
                              );
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              child: Row(
                                children: [
                                  // Cover Image
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            mediaItem.artUri?.toString() ?? "",
                                        width: 48.w,
                                        height: 48.w,
                                        fit: BoxFit.cover,
                                        errorWidget:
                                            (context, url, error) => Container(
                                              color: Colors.white10,
                                              child: Icon(
                                                Icons.music_note,
                                                color: Colors.white54,
                                                size: 20.sp,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  // Title & Description
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mediaItem.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          mediaItem.artist ?? "Sapere",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: AppColors.kSamiOrange,
                                        size: 26.sp,
                                      ),
                                      onPressed: () {
                                        if (isPlaying) {
                                          audioHandler.pause();
                                        } else {
                                          audioHandler.play();
                                        }
                                      },
                                      constraints: BoxConstraints.tightFor(
                                        width: 40.w,
                                        height: 40.w,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  IconButton(
                                    icon: Icon(
                                      Icons.forward_10_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 24.sp,
                                    ),
                                    onPressed: () => audioHandler.skipToNext(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  SizedBox(width: 12.w),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white38,
                                      size: 22.sp,
                                    ),
                                    onPressed: () => audioHandler.stop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
