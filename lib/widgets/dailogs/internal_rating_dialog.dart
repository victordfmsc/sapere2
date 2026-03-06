import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:sapere/core/services/app_rating_service.dart';

class InternalRatingDialog extends StatefulWidget {
  const InternalRatingDialog({super.key});

  @override
  State<InternalRatingDialog> createState() => _InternalRatingDialogState();
}

class _InternalRatingDialogState extends State<InternalRatingDialog> {
  double _currentRating = 5.0;
  bool _showFeedbackForm = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleLater() {
    AppRatingService.instance.dismissForSession();
    Navigator.pop(context);
  }

  void _handleSubmitFeedback() {
    // In a real app, send _feedbackController.text to backend/analytics
    AppRatingService.instance.setHasRatedApp(true);
    Navigator.pop(context);

    // Optional: show a small snackbar thanking them
    Get.snackbar(
      '',
      '',
      titleText: const SizedBox.shrink(),
      messageText: Text(
        'ratingFeedbackSuccess'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: AppColors.kSamiOrange.withOpacity(0.9),
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(20.w),
      borderRadius: 16.r,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            decoration: BoxDecoration(
              color: AppColors.kGlassBackground,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: AppColors.kGlassBorder.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.kSamiOrange.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  _showFeedbackForm ? _buildFeedbackForm() : _buildRatingForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingForm() {
    return Column(
      key: const ValueKey('RatingForm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarGlow(
          glowColor: AppColors.kSamiOrange,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.textColor.withOpacity(0.2),
                  AppColors.kSamiOrange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.kSamiOrange.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kSamiOrange.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.stars_rounded,
              color: AppColors.kSamiOrange,
              size: 48.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          "ratingTitle".tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSerifDisplay',
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12.h),
        // Incentive banner - highlighted
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.kGoldGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            "ratingIncentive".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            "ratingMessage".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 32.h),
        RatingBar.builder(
          initialRating: 1, // Start low to encourage interaction
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemPadding: EdgeInsets.symmetric(horizontal: 6.w),
          unratedColor: Colors.white12,
          itemBuilder:
              (context, _) =>
                  Icon(Icons.star_rounded, color: AppColors.kSamiOrange),
          onRatingUpdate: (rating) {
            setState(() {
              _currentRating = rating;
            });
          },
        ),
        if (_currentRating >= 1) ...[
          SizedBox(height: 36.h),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: [AppColors.textColor, AppColors.kSamiOrange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kSamiOrange.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentRating >= 4.0) {
                        // High rating -> trigger native in-app review flow
                        Navigator.pop(context);
                        await AppRatingService.instance.setHasRatedApp(true);
                        await AppRatingService.instance.triggerNativeReview();
                      } else {
                        // Low rating -> show feedback form
                        setState(() {
                          _showFeedbackForm = true;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      "ratingRateNow".tr,
                      style: TextStyle(
                        color: AppColors.kDeepBlack,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: _handleLater,
                style: TextButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Text(
                  "ratingLater".tr,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      key: const ValueKey('FeedbackForm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.feedback_rounded, color: AppColors.kSamiOrange, size: 48.sp),
        SizedBox(height: 16.h),
        Text(
          "ratingFeedbackTitle".tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        TextField(
          controller: _feedbackController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "ratingFeedbackPlaceholder".tr,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.kSamiOrange, width: 1),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                colors: [AppColors.textColor, AppColors.kSamiOrange],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _handleSubmitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                "ratingFeedbackSubmit".tr,
                style: TextStyle(
                  color: AppColors.kDeepBlack,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () {
            setState(() {
              _showFeedbackForm = false; // Go back to rating
            });
          },
          child: Text(
            "ratingLater".tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
