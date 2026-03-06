import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/services/app_rating_service.dart';
import 'package:sapere/routes/app_pages.dart';

class CreationSuccessDialog extends StatelessWidget {
  final String credits;

  const CreationSuccessDialog({super.key, required this.credits});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              width: 1.5,
              color: const Color(
                0xFFFFD700,
              ).withOpacity(0.2), // Subtle gold border
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.05),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // High-Impact Visual Composition
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Animated-like Icon Composition
                  ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: AppColors.kGoldGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 70.sp,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star_rounded,
                              size: 24.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),

              // Persuasive Title
              Text(
                'ratingTitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textColor,
                  fontFamily: 'NotoSerifDisplay',
                ),
              ),
              SizedBox(height: 16.h),

              // Incentive Message
              Text(
                'ratingIncentive'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.5,
                  color: AppColors.textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),

              // "Materialized" Credit Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.greenAccent,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'remainingCredits'.trArgs([credits]),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Primary CTA: Rate & Unlock
              GestureDetector(
                onTap: () {
                  // Pop this dialog and show the internal rating dialog
                  Navigator.pop(context);
                  AppRatingService.instance.maybeShowRatingDialog(
                    Get.overlayContext!,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.kGoldGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'ratingRateNow'.tr.toUpperCase(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Secondary CTA: Just go to dashboard
              TextButton(
                onPressed: () => Get.offAllNamed(Routes.dashboardScreen),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'maybeLater'.tr,
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.4),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
