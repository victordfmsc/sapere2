import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
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
          child: Stack(
            children: [
              // --- Close Button (Top Right) ---
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Get.offAllNamed(Routes.dashboardScreen),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 20.sp,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(32.w, 48.h, 32.w, 32.h),
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
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
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
                      'bukBukCreated'.tr,
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
                      'bukBukCreatedAndUploaded'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.5,
                        color: AppColors.textColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // "Materialized" Credit Status & Achievement
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.kSamiOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: AppColors.kSamiOrange.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_outline_rounded,
                                color: AppColors.kSamiOrange,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                '-1 ${'saperePoints'.tr.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Divider(
                              color: Colors.white.withOpacity(0.05),
                              height: 1,
                            ),
                          ),
                          Text(
                            'remainingCredits'.trArgs([credits]),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Primary CTA: Continue to Home
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Standardized Redirection to Home
                          Get.offAllNamed(Routes.dashboardScreen);
                        },
                        borderRadius: BorderRadius.circular(16.r),
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
                              'continueText'.tr.toUpperCase(),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
