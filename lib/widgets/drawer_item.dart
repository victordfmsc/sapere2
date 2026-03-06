// import 'package:daiaryapp/res/colors.dart';
// import 'package:daiaryapp/res/icons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
//
// class profileCards extends StatelessWidget {
//   final String title;
//   final bool isSvg;
//   final void Function()? onTap;
//   final String svgIcon;
//   const profileCards({
//     super.key,
//     required this.title,
//     this.onTap,
//     required this.svgIcon,
//     this.isSvg = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final TextTheme appTextStyle = Theme.of(context).textTheme;
//     return Padding(
//       padding: const EdgeInsets.all(10.0),
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           width: 382.w,
//           decoration: BoxDecoration(
//               shape: BoxShape.rectangle,
//               color: AppColors.kFillColor,
//               borderRadius: BorderRadius.circular(7),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.kFillColor,
//                   offset: const Offset(
//                     6.0,
//                     6.0,
//                   ),
//                   blurRadius: 14.0,
//                   spreadRadius: 12.0,
//                 )
//               ]),
//           child: Container(
//             width: 382.w,
//             padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h)
//                 .copyWith(bottom: 0),
//             child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 55.w,
//                     height: 55.h,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppColors.whiteColor,
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(14.0),
//                       child: isSvg == false
//                           ? SvgPicture.asset(
//                               svgIcon,
//                               width: 24.w,
//                               height: 24.h,
//                               color: AppColors.primaryColor,
//                             )
//                           : Icon(
//                               Icons.bookmark,
//                               color: AppColors.primaryColor,
//                             ),
//                     ),
//                   ),
//                   Flexible(
//                     child: Text(
//                       title.tr,
//                       style: appTextStyle.titleSmall!.copyWith(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 16.sp,
//                           color: AppColors.primaryColor),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   SvgPicture.asset(
//                     AppIcons.kForwordArrow,
//                     color: AppColors.primaryColor,
//                   )
//                 ]),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class DrawerCard extends StatelessWidget {
  final String title;
  final bool isSvg;
  final IconData? iconData;
  final void Function()? onTap;
  final String svgIcon;
  final bool isDrawer;

  const DrawerCard({
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          isSvg == false
              ? SvgPicture.asset(
                svgIcon,
                width: 40.w,
                height: 40.h,
                color: AppColors.textColor,
                // color: isDrawer ? AppColors.textColor : AppColors.textColor,
              )
              : Icon(iconData, size: 40.w, color: AppColors.textColor),
          SizedBox(width: 15.w),
          Flexible(
            child: Text(
              title.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appTextStyle.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
