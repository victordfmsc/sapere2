
 
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
 

class SuccessDialog extends StatelessWidget {
  final String title, subTitle, buttonText, svgIcon;
  final void Function() onTap;
  const SuccessDialog(
      {super.key,
      required this.title,
      required this.subTitle,
      required this.buttonText,
      required this.onTap,
      required this.svgIcon});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Dialog(
      elevation: 0,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.r)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180.w,
              height: 180.h,
              child: SvgPicture.asset(svgIcon),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.tr,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24.sp),
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    Text(
                      subTitle.tr,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge!.copyWith(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 16.sp),
                    )
                  ]),
            ),
            PrimaryButton(
              elevation: 0,
              onTap: onTap,
              text: buttonText.tr,
              bgColor: AppColors.primaryColor,
              borderRadius: 100.r,
              height: 60.h,
              textColor: AppColors.whiteColor,
              width: 279.w,
              fontSize: 14.sp,
            ),
          ],
        ),
      ),
    );
  }
}
