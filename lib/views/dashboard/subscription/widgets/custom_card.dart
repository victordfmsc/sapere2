// import 'package:daiaryapp/res/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
//
// class CustomSubscriptionCard extends StatefulWidget {
//   final VoidCallback onTap;
//   final String name;
//   final String price;
//   const CustomSubscriptionCard(
//       {super.key,
//       required this.onTap,
//       required this.name,
//       required this.price});
//
//   @override
//   State<CustomSubscriptionCard> createState() => _CustomSubscriptionCardState();
// }
//
// class _CustomSubscriptionCardState extends State<CustomSubscriptionCard> {
//   @override
//   Widget build(BuildContext context) {
//     TextTheme textTheme = Theme.of(context).textTheme;
//
//     return InkWell(
//       onTap: widget.onTap,
//       child: Padding(
//         padding: const EdgeInsets.all(8).copyWith(left: 0),
//         child: Container(
//           width: Get.width * 0.28,
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//               border: Border.all(
//                 color: AppColors.primaryColor,
//               ),
//               // : null,
//               borderRadius: BorderRadius.circular(16.r),
//               color: AppColors.whiteLightColor),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               Text(
//                 widget.name,
//                 textAlign: TextAlign.center,
//                 style: textTheme.displayLarge!.copyWith(
//                   fontSize: 16.sp,
//                   color: AppColors.lightBlackColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'premium'.tr,
//                 style: textTheme.displayLarge!.copyWith(
//                   fontSize: 16.sp,
//                   color: AppColors.lightBlackColor,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               Text(
//                 widget.price,
//                 style: textTheme.displayLarge!.copyWith(
//                   fontSize: 15.sp,
//                   color: AppColors.lightBlackColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

Widget buildFeatureItem(String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text("• ✅ $text.tr", style: TextStyle(fontSize: 17.sp)),
    ),
  );
}

Widget buildSubscriptionOption({
  required String title,
  required String subTitle,
  required VoidCallback onTap,
  required String price,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: Get.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            price,
            style: TextStyle(
              fontSize: 32.sp,
              color: AppColors.whiteColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subTitle,
            style: TextStyle(
              fontSize: 15.sp,
              color: AppColors.whiteColor.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildSubscriptionOptionWeekly({
  required String title,
  required String subTitle,
  required VoidCallback onTap,
  required String price,
}) {
  return InkWell(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: Get.width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xffD4AF37), // Gold
                AppColors.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffD4AF37).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: const Color(0xffD4AF37).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32.sp,
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.whiteColor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffFFD700), Color(0xffFFA500)],
              ),
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              "freeTrailWeek".tr.toUpperCase(),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
