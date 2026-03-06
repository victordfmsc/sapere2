import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constant/colors.dart';

class PremiumSuccessDialog extends StatelessWidget {
  final String points;

  const PremiumSuccessDialog({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Container(
          width: 0.85.sw,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.kDeepBlack.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.kGlassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.textColor.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold Icon with Glow
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textColor.withOpacity(0.1),
                ),
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: AppColors.kGoldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                  child: Icon(
                    Icons.stars_rounded,
                    size: 60.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                'subscriptionSuccessTitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                'subscriptionSuccessMessage'.trArgs([points]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),

              // Cumulative Info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'creditsCumulativeInfo'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.8),
                    fontSize: 13.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // Close Button
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.kGoldGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textColor.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'closeBtn'.tr,
                      style: TextStyle(
                        color: AppColors.kDeepBlack,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
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
