import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sapere/providers/subscription_provider.dart';
import '../../../../core/services/app_rating_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sapere/widgets/sapere_image.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../routes/app_pages.dart';
import 'package:sapere/views/dashboard/commuinty/widgets/sapere_reader_screen.dart';
import '../audio_player/audio_player.dart';

class SapereDetails extends StatefulWidget {
  final BukBukPost post;

  const SapereDetails({super.key, required this.post});

  @override
  State<SapereDetails> createState() => _SapereDetailsState();
}

class _SapereDetailsState extends State<SapereDetails> {
  String? codeLang;
  String? _sapereUrl;
  Timer? _pollTimer;
  List<String>? _description;
  @override
  void initState() {
    super.initState();
    _checkSapereUrlOnce().then((_) => _startPollingIfNeeded(context));

    _loadLanguage();
  }

  Future<void> _checkSapereUrlOnce() async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection(sapereCollection)
              .doc(widget.post.postId)
              .get();

      final data = snap.data();

      final String? url = (data?['bukbukUrl'] as String?)?.trim();

      final List<String>? desc =
          (data?['description'] as List?)?.whereType<String>().toList();

      if (!mounted) return;

      setState(() {
        _sapereUrl = (url != null && url.isNotEmpty) ? url : null;
        _description = (desc != null && desc.isNotEmpty) ? desc : _description;
      });

      if (_sapereUrl != null && _sapereUrl!.isNotEmpty) {
        _pollTimer?.cancel();
        _pollTimer = null;
      } else {
        setState(() {
          _sapereUrl = null;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _startPollingIfNeeded(BuildContext context) {
    if (_sapereUrl != null && _sapereUrl!.isNotEmpty) return;

    _pollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      provider.fetchUserData();

      _checkSapereUrlOnce();
    });
  }

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    setState(() {
      codeLang = storedLang ?? 'en_US';
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (codeLang == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final List<String>? effectiveDesc = _description ?? widget.post.description;
    final String fullText =
        (effectiveDesc != null && effectiveDesc.isNotEmpty)
            ? effectiveDesc.join('\n\n').trim()
            : "";

    // Simple summary logic: first paragraph or first 200 characters
    final String summary = fullText.split('\n\n').first;

    return Scaffold(
      backgroundColor: Colors.black, // Premium dark base
      body: CustomScrollView(
        slivers: [
          // 1. Full Screen Header Image with Gradient & Play Button
          SliverAppBar(
            expandedHeight: 480.h,
            backgroundColor: Colors.black,
            elevation: 0,
            leadingWidth: 70,
            leading: Padding(
              padding: EdgeInsets.only(left: 15.w, top: 10.h),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 20.w, top: 10.h),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          Provider.of<UserProvider>(
                            context,
                          ).user?.profileImage ??
                          "",
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) =>
                              Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  SapereImage(
                    imageUrl: widget.post.newCover.toString(),
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.9),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Info
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.post.sapereName ?? 'sapere',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Metadata Row (Rating style / Type)
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.kSamiOrange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "SAPERE 1.0",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.star, color: Colors.amber, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        "9.8",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'aiGenerated'.tr,
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Taglines (Categories)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _buildPillTag(
                        widget.post.sapereCategoryNames![codeLang] ?? "",
                      ),
                      _buildPillTag(
                        widget.post.sapereTypeNames![codeLang] ?? "",
                      ),
                      _buildPillTag(widget.post.language ?? ""),
                    ],
                  ),
                  SizedBox(height: 25.h),

                  // Premium Action Buttons
                  Row(
                    children: [
                      // Play Button
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap:
                              _sapereUrl == null
                                  ? () {
                                    Get.snackbar(
                                      'info'.tr,
                                      'generatingText'.tr,
                                      backgroundColor: AppColors.primaryColor,
                                      colorText: AppColors.whiteColor,
                                    );
                                  }
                                  : () {
                                    final iap =
                                        Provider.of<InAppPurchaseProvider>(
                                          context,
                                          listen: false,
                                        );
                                    if (!iap.isSubscribed &&
                                        !AppRatingService
                                            .instance
                                            .hasRatedApp) {
                                      AppRatingService.instance
                                          .maybeShowRatingDialog(context);
                                      return;
                                    }
                                    Get.to(
                                      () =>
                                          AudioPlayerScreen(post: widget.post),
                                    );
                                  },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            height: 60.h,
                            decoration:
                                _sapereUrl == null
                                    ? BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(color: Colors.white24),
                                    )
                                    : BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppColors.kGoldGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.kSamiOrange
                                              .withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  color:
                                      _sapereUrl == null
                                          ? Colors.white38
                                          : Colors.black87,
                                  size: 28.sp,
                                ),
                                if (_sapereUrl != null) ...[
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Play',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      // Read Button
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap:
                              (_sapereUrl == null || fullText.isEmpty)
                                  ? () {
                                    Get.snackbar(
                                      'info'.tr,
                                      'generatingText'.tr,
                                      backgroundColor: AppColors.primaryColor,
                                      colorText: AppColors.whiteColor,
                                    );
                                  }
                                  : () {
                                    final iap =
                                        Provider.of<InAppPurchaseProvider>(
                                          context,
                                          listen: false,
                                        );
                                    if (!iap.isSubscribed &&
                                        !AppRatingService
                                            .instance
                                            .hasRatedApp) {
                                      AppRatingService.instance
                                          .maybeShowRatingDialog(context);
                                      return;
                                    }
                                    Get.to(
                                      () => SapereReaderScreen(
                                        postId: widget.post.postId,
                                        title:
                                            widget.post.sapereName.toString(),
                                        content: fullText,
                                        audioUrl: _sapereUrl,
                                        coverUrl:
                                            widget.post.newCover.toString(),
                                      ),
                                    );
                                  },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            height: 60.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'openBook'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (FirebaseAuth.instance.currentUser?.uid ==
                          widget.post.uId)
                        Padding(
                          padding: EdgeInsets.only(left: 15.w),
                          child: InkWell(
                            onTap: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection(sapereCollection)
                                    .doc(widget.post.postId)
                                    .delete();
                                Navigator.pushReplacementNamed(
                                  context,
                                  Routes.dashboardScreen,
                                );
                              } catch (e) {
                                print('Error deleting document: $e');
                              }
                            },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              height: 60.h,
                              width: 60.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent.withOpacity(0.8),
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 35.h),

                  // Summary Section
                  Text(
                    'summaryTitle'.tr,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    summary,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: (_sapereUrl == null) ? 20.h : 60.h),

                  // Generation Banner if needed
                  if (_sapereUrl == null || _sapereUrl!.isEmpty)
                    audioGeneratingBanner(),

                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label) {
    if (label.isEmpty) return const SizedBox();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 13.sp),
      ),
    );
  }

  Widget audioGeneratingBanner() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SpinKitPulse(color: AppColors.kSamiOrange, size: 30.sp),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'audioBookGenerating'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'itWillAvailableSoon'.tr,
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
