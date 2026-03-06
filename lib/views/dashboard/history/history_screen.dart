import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/models/history_item.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/providers/history_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sapere/widgets/sapere_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import '../stream/audio_player/audio_player.dart';
import '../commuinty/widgets/sapere_reader_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<HistoryProvider>(
          builder: (context, provider, child) {
            final historyItems = provider.history;

            if (historyItems.isEmpty) {
              return _buildEmptyState();
            }

            final latestItem = historyItems.first;
            final otherItems = historyItems.skip(1).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "historyTitle".tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSerifDisplay',
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "historySubtitle".tr,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // HIGHLIGHT: CONTINUE LAST
                SliverToBoxAdapter(child: _buildFeaturedItem(latestItem)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 20.h,
                    ),
                    child: Text(
                      "recentActivity".tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildHistoryListItem(otherItems[index]);
                    }, childCount: otherItems.length),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white24, size: 80.sp),
          SizedBox(height: 16.h),
          Text(
            "noHistoryYet".tr,
            style: TextStyle(color: Colors.white60, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItem(HistoryItem item) {
    return GestureDetector(
      onTap: () => _resumeItem(item),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        constraints: BoxConstraints(minHeight: 200.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          image: DecorationImage(
            image: CachedNetworkImageProvider(item.coverUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.type == 'audio'
                      ? "audio".tr.toUpperCase()
                      : "book".tr.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildProgressBar(item)),
                  SizedBox(width: 16.w),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryListItem(HistoryItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => _resumeItem(item),
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SapereImage(
                imageUrl: item.coverUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.type == 'audio'
                        ? "historyAudio".tr
                        : "historyReading".tr,
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                  SizedBox(height: 8.h),
                  _buildProgressBar(item, height: 4),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _resumeItem(item),
              icon: Icon(
                item.type == 'audio'
                    ? Icons.play_circle_outline
                    : Icons.menu_book,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(HistoryItem item, {double height = 6}) {
    double progress = 0.0;
    if (item.type == 'audio') {
      if (item.totalDurationMs > 0) {
        progress = item.positionMs / item.totalDurationMs;
      }
    } else {
      progress = 0.5; // Placeholder
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: height.h,
          ),
        ),
      ],
    );
  }

  void _resumeItem(HistoryItem item) async {
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.white)),
      barrierDismissible: false,
    );

    try {
      // Fetch post from Firestore
      final snap =
          await FirebaseFirestore.instance
              .collection(sapereCollection)
              .doc(item.id)
              .get();

      Get.back(); // Hide loading

      if (snap.exists) {
        final post = BukBukPost.fromFirestore(snap);

        if (item.type == 'audio') {
          Get.to(
            () => AudioPlayerScreen(
              post: post,
              initialPosition: Duration(milliseconds: item.positionMs),
            ),
          );
        } else {
          final List<String> description = List<String>.from(
            snap.data()?['description'] ?? [],
          );
          final String fullText = description.join('\n\n').trim();

          Get.to(
            () => SapereReaderScreen(
              postId: post.postId,
              title: post.sapereName ?? "Sapere",
              content: fullText,
              audioUrl: post.sapereUrl,
              coverUrl: post.newCover,
              initialOffset: item.scrollOffset,
            ),
          );
        }
      } else {
        Get.snackbar("Error", "noDataFound".tr);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString());
    }
  }
}
