import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/widgets/primary_button.dart';

class CreationMotivatorDialog extends StatelessWidget {
  const CreationMotivatorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: AppColors.kSamiOrange.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.kSamiOrange.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inspirational Icon
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.kSamiOrange.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.kSamiOrange.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.kSamiOrange,
                  size: 48.sp,
                ),
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                "creandoSapere".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 16.h),

              // Motivating copy
              Text(
                "Congratulations on investing in your knowledge! Your Audio Documentary is being generated. This takes a few minutes, but it will be ready in your Creations tab soon.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 32.h),

              // Done Button
              PrimaryButton(
                width: double.infinity,
                text: "continue".tr,
                bgColor: AppColors.kSamiOrange,
                textColor: Colors.white,
                onTap: () {
                  Get.back(); // close dialog
                  Get.back(); // close AddSaperePage if needed or just go home
                  Get.offNamedUntil('/dashboard', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
