import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/routes/app_pages.dart';

class OutOfCreditsDialog extends StatelessWidget {
  final DateTime? nextRefillDate;

  const OutOfCreditsDialog({super.key, this.nextRefillDate});

  @override
  Widget build(BuildContext context) {
    String formattedDate = '---';
    if (nextRefillDate != null) {
      formattedDate = DateFormat('dd MMMM yyyy').format(nextRefillDate!);
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: AppColors.whiteColor.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // --- Close Button (Top Right) ---
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
                  // Icon with glow
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.auto_awesome_motion_outlined,
                      color: AppColors.primaryColor,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Text(
                    'outOfPointsTitle'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Description
                  Text(
                    'outOfPointsDesc'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.whiteColor.withOpacity(0.7),
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Next Refill Info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.whiteColor.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'nextRefillInfo'.tr,
                          style: TextStyle(
                            color: AppColors.whiteColor.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Primary Action
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(Routes.subscriptionPage);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 55.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'getMorePointsBtn'.tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Secondary Dismiss
                  TextButton(
                    onPressed: () => Get.offAllNamed(Routes.dashboardScreen),
                    child: Text(
                      'close'.tr,
                      style: TextStyle(
                        color: AppColors.whiteColor.withOpacity(0.4),
                        fontSize: 14.sp,
                      ),
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
}
