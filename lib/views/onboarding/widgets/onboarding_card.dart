import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

class IntroWidget extends StatelessWidget {
  final String name;
  final String image;
  final int index;
  final String description;
  final Color primaryColor;
  final Color secondary;
  final VoidCallback onSkipTap;
  final VoidCallback onContinueTap;
  const IntroWidget({
    super.key,
    required this.name,
    required this.image,
    required this.index,
    required this.description,
    required this.onSkipTap,
    required this.onContinueTap,
    required this.primaryColor,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      height: Get.height,
      child: Stack(
        children: [
          // Full-screen Premium Background Image
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(image),
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 1.05, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Image.asset(image, fit: BoxFit.cover),
                );
              },
            ),
          ),

          // Dark Gradient overlay to ensure text is always readable
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                    AppColors.blackColor,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content Layout
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),
                  // App Branding
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'SAPERE'.tr.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4.0,
                        fontFamily: 'NotoSerifDisplay',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Glassmorphism Text Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.whiteColor,
                                letterSpacing: 0.5,
                                fontFamily: 'NotoSerifDisplay',
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.whiteColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  // Pagination
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: i == index ? 24.w : 8.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              i == index
                                  ? AppColors.textColor
                                  : AppColors.whiteColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  // Buttons
                  Row(
                    children: [
                      if (index != 2)
                        Expanded(
                          child: TextButton(
                            onPressed: onSkipTap,
                            child: Text(
                              'skipText'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.whiteColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: onContinueTap,
                          child: Container(
                            height: 56.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xffD4AF37), // Gold
                                  Color(0xffB8860B), // Darker Gold
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xffD4AF37,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                index == 2 ? 'getText'.tr : 'nextText'.tr,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
