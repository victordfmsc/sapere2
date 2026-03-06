import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/widgets/sapere_image.dart';
import 'package:provider/provider.dart';
import 'package:sapere/providers/user_provider.dart';

import '../../../../main.dart'; // To stop global audioHandler if needed

class PreviewReelsScreen extends StatefulWidget {
  final BukBukPost initialPost;

  const PreviewReelsScreen({super.key, required this.initialPost});

  @override
  State<PreviewReelsScreen> createState() => _PreviewReelsScreenState();
}

class _PreviewReelsScreenState extends State<PreviewReelsScreen> {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<BukBukPost> _previews = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchPreviews();
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

  Future<void> _fetchPreviews() async {
    try {
      final localeProvider = Get.locale?.toString() ?? 'en_US';

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(sapereCollection)
              .where('type', isEqualTo: 'preview')
              .where('languageCode', isEqualTo: localeProvider)
              .orderBy('publishTime', descending: true)
              .get();

      final fetchedPosts =
          querySnapshot.docs
              .map(
                (doc) => BukBukPost.fromMap(doc.data().cast<String, dynamic>()),
              )
              .toList();

      // Ensure the initial post is in the list, or put it first if it isn't
      int initialIndex = fetchedPosts.indexWhere(
        (p) => p.postId == widget.initialPost.postId,
      );

      setState(() {
        _previews = fetchedPosts;
        if (initialIndex != -1) {
          _currentIndex = initialIndex;
        } else {
          _previews.insert(0, widget.initialPost);
          _currentIndex = 0;
        }
        _isLoading = false;
      });

      // Jump to the initial page after frame builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && _currentIndex > 0) {
          _pageController.jumpToPage(_currentIndex);
        }
        _playCurrentPreview();
      });
    } catch (e) {
      print("Error fetching previews: $e");
      setState(() {
        _isLoading = false;
        _previews = [widget.initialPost];
      });
      _playCurrentPreview();
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

    // Stop global background player if running
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
          "previews".tr.toUpperCase(),
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
        if (snapshot.hasData && snapshot.data!.exists) {
          final updatedData = snapshot.data!.data() as Map<String, dynamic>;
          // Keep important metadata like the document ID
          updatedData['postId'] = post.postId;
          post = BukBukPost.fromMap(updatedData);
        }

        final isGenerating = post.sapereUrl == null || post.sapereUrl!.isEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            SapereImage(imageUrl: post.newCover.toString(), fit: BoxFit.cover),

            // Gradient overlay for text readability
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

            // Content
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play/Pause Button Indicator
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () async {
                          if (isGenerating) return;
                          // Toggle play/pause for the current active post
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

                  // Title
                  Text(
                    post.sapereName ?? "Preview",
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

                  // Captions / Generated Text or Status
                  if (!isGenerating &&
                      post.description != null &&
                      post.description!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      constraints: BoxConstraints(maxHeight: 250.h),
                      child: SingleChildScrollView(
                        child: Text(
                          post.description!.join('\n\n'),
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
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kSamiOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.kSamiOrange),
                      ),
                      child: Text(
                        "audioBookGenerating".tr,
                        style: TextStyle(
                          color: AppColors.kSamiOrange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    final isSaved = userProvider.isReelSaved(post.postId!);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            userProvider.updateSavedReel(
                              post.postId!,
                              !isSaved,
                            );
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
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
                                  shadows: [
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
