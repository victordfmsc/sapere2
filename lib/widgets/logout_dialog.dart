// ignore_for_file: must_be_immutable

import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'primary_button.dart';

class LogOutDialog extends StatelessWidget {
  const LogOutDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;
    return AlertDialog(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34.r)),
      titlePadding: EdgeInsets.zero,
      backgroundColor: AppColors.kFillColor,
      content: Padding(
        padding: EdgeInsets.only(left: 24.w, top: 32.h, right: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 102.w,
              height: 102.h,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.whiteColor),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: SvgPicture.asset(
                  AppImagesUrls.kLogOut,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(
              height: 24.h,
            ),
            Text(
              'wantToLogout'.tr,
              textAlign: TextAlign.center,
              style: appTextStyle.displayMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 22.sp,
                  color: AppColors.primaryColor),
            ),
            SizedBox(
              height: 12.h,
            ),
            SizedBox(
              width: 200.w,
              height: 36.h,
              child: Text(
                'logoutSubText'.tr,
                textAlign: TextAlign.center,
                style: appTextStyle.bodySmall!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    color: AppColors.primaryColor),
              ),
            ),
            SizedBox(
              height: 32.h,
            ),
            PrimaryButton(
              onTap: () async {
                // await auth.signOut();
              },
              width: 382.w,
              text: 'logoutTitle'.tr,
              textColor: AppColors.whiteColor,
              bgColor: AppColors.primaryColor,
              borderRadius: 100,
              fontSize: 14,
              height: 62.h,
              elevation: 0,
            ),
          ],
        ),
      ),
    );
  }
}
