import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/widgets/sapere_image.dart';

import '../../../../main.dart'; // To stop global audioHandler if needed

class SavedReelsScreen extends StatefulWidget {
  const SavedReelsScreen({super.key});

  @override
  State<SavedReelsScreen> createState() => _SavedReelsScreenState();
}

class _SavedReelsScreenState extends State<SavedReelsScreen> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<BukBukPost> _previews = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedReels();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
  }

  Future<void> _fetchSavedReels() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final savedIds = userProvider.user?.savedReels ?? [];

      if (savedIds.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _previews = [];
          });
        }
        return;
      }

      List<BukBukPost> fetchedPosts = [];

      // Firestore whereIn has a max limit of 10 items
      for (var i = 0; i < savedIds.length; i += 10) {
        final batch = savedIds.skip(i).take(10).toList();
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection(sapereCollection)
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        fetchedPosts.addAll(
          querySnapshot.docs
              .map((doc) => BukBukPost.fromFirestore(doc))
              .toList(),
        );
      }

      // Sort to match the order in savedIds (latest saved first usually, or just leave as is)

      if (mounted) {
        setState(() {
          _previews = fetchedPosts;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playCurrentPreview();
        });
      }
    } catch (e) {
      print("Error fetching saved reels: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _playCurrentPreview();
  }

  Future<void> _playCurrentPreview() async {
    if (_previews.isEmpty) return;
    final currentPost = _previews[_currentIndex];
    audioHandler.pause();

    try {
      if (currentPost.sapereUrl != null && currentPost.sapereUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(currentPost.sapereUrl!);
        await _audioPlayer.play();
      } else {
        await _audioPlayer.stop();
      }
    } catch (e) {
      print("Error playing preview: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: () {
            _audioPlayer.stop();
            Get.back();
          },
        ),
        title: Text(
          "Guardados".toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _previews.isEmpty
              ? Center(
                child: Text(
                  "emptyPost".tr, // Or a dedicated string for "No saved reels"
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              )
              : PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: _previews.length,
                itemBuilder: (context, index) {
                  final post = _previews[index];
                  return _buildReelPage(post);
                },
              ),
    );
  }

  Widget _buildReelPage(BukBukPost post) {
    if (post.postId == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(sapereCollection)
              .doc(post.postId)
              .snapshots(),
      builder: (context, snapshot) {
        BukBukPost currentPost = post;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentPost = BukBukPost.fromFirestore(snapshot.data!);
        }

        final isGenerating =
            currentPost.sapereUrl == null || currentPost.sapereUrl!.isEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            SapereImage(
              imageUrl: currentPost.newCover.toString(),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () async {
                          if (isGenerating) return;
                          if (_currentIndex == _previews.indexOf(post)) {
                            if (_audioPlayer.playing) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.play();
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          child:
                              isGenerating
                                  ? SizedBox(
                                    width: 24.sp,
                                    height: 24.sp,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    _currentIndex == _previews.indexOf(post) &&
                                            _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32.sp,
                                  ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    currentPost.sapereName ?? "Preview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (!isGenerating &&
                      currentPost.description != null &&
                      currentPost.description!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      constraints: BoxConstraints(maxHeight: 250.h),
                      child: SingleChildScrollView(
                        child: Text(
                          currentPost.description!.join('\n\n'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.9),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 1,
                                offset: const Offset(-1, -1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (!isGenerating)
                    Text(
                      "short_summary_desc".tr,
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                ],
              ),
            ),

            // Actions (Right side)
            if (!isGenerating)
              Positioned(
                bottom: 120.h,
                right: 16.w,
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final isSaved = userProvider.isReelSaved(
                      currentPost.postId!,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            userProvider.updateSavedReel(
                              currentPost.postId!,
                              !isSaved,
                            );
                            // Optionally, if they un-save it here, we don't instantly remove it from the list to avoid jank. Refresh on next load.
                          },
                          child: Column(
                            children: [
                              Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color:
                                    isSaved
                                        ? AppColors.kSamiOrange
                                        : Colors.white,
                                size: 36.sp,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "save".tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
