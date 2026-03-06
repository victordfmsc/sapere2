// import 'package:sapere/core/constant/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
//
// class CustomProgressBar extends StatefulWidget {
//   final String progressPercentage;
//   final String numberOfBooks;
//   final double progress;
//   const CustomProgressBar(
//       {super.key,
//       required this.progressPercentage,
//       required this.numberOfBooks,
//       required this.progress});
//
//   @override
//   State<CustomProgressBar> createState() => _CustomProgressBarState();
// }
//
// class _CustomProgressBarState extends State<CustomProgressBar> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       margin: const EdgeInsets.symmetric(horizontal: 16.0),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//               color: AppColors.primaryColor, blurRadius: 2, spreadRadius: .02),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(height: 8.h),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${widget.progressPercentage}% ${'toComplete'.tr}',
//                 style: TextStyle(
//                   fontSize: 17.sp,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.book,
//                     color: AppColors.primaryColor,
//                   ),
//                   SizedBox(width: 4.h),
//                   Text(
//                     '${'books'.tr}: ${widget.numberOfBooks}',
//                     style: TextStyle(
//                         color: AppColors.blackColor,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           SizedBox(height: 5.h),
//           LinearProgressIndicator(
//             value: widget.progress,
//             backgroundColor: Colors.grey[300],
//             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
//             minHeight: 8.0,
//             borderRadius: BorderRadius.circular(15),
//           ),
//           SizedBox(height: 12.h),
//         ],
//       ),
//     );
//   }
// }
