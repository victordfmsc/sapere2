import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ProfileCards extends StatelessWidget {
  final String title;
  final bool isSvg;
  final IconData? iconData;
  final void Function()? onTap;
  final String svgIcon;
  final bool isDrawer;

  const ProfileCards({
    super.key,
    required this.title,
    this.onTap,
    required this.svgIcon,
    this.isSvg = false,
    required this.isDrawer,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        isSvg == false
            ? SvgPicture.asset(
                svgIcon,
                width: 40.w,
                height: 40.h,
                color: AppColors.whiteColor,
              )
            : Icon(
                iconData,
                size: 40.w,
                color: AppColors.whiteColor,
              ),
        SizedBox(width: 20.h),
        Text(
          title.tr,
          style: appTextStyle.titleSmall!.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
            color: AppColors.whiteColor,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
