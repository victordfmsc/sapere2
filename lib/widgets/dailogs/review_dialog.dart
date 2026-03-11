import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:sapere/routes/app_pages.dart';

class ReviewDialog extends StatelessWidget {
  final VoidCallback onRate;
  final VoidCallback onLater;

  const ReviewDialog({super.key, required this.onRate, required this.onLater});

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
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
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
                Column(
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
                          Icons.star_rounded,
                          color: AppColors.kSamiOrange,
                          size: 48.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      "enjoyingSapere".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSerifDisplay',
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        "rateUsDescription".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15.sp,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            Icons.star_rounded,
                            color: AppColors.kSamiOrange,
                            size: 38.sp,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 36.h),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.textColor,
                                  AppColors.kSamiOrange,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.kSamiOrange.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                onRate();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 18.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                "rateNow".tr,
                                style: TextStyle(
                                  color: AppColors.kDeepBlack,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: onLater,
                          style: TextButton.styleFrom(
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: Text(
                            "maybeLater".tr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
