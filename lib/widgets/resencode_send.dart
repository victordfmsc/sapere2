// import 'dart:async';
// import 'dart:developer';
// import 'package:sapere/core/constant/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
//
// class ResendCodeScreen extends StatefulWidget {
//   const ResendCodeScreen({super.key});
//
//   @override
//   _ResendCodeScreenState createState() => _ResendCodeScreenState();
// }
//
// class _ResendCodeScreenState extends State<ResendCodeScreen> {
//   RxInt countdownSeconds = 60.obs;
//   Timer? countdownTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     startCountdown();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     countdownTimer!.cancel();
//   }
//
//   void startCountdown() {
//     try {
//       const oneSec = Duration(seconds: 1);
//       countdownTimer = Timer.periodic(oneSec, (timer) {
//         if (countdownSeconds.value > 0) {
//           countdownSeconds.value--;
//         } else {
//           countdownTimer!.cancel();
//         }
//       });
//     } catch (e) {
//       log(e.toString());
//     }
//   }
//
//   void resendCode() {
//     countdownSeconds.value = 60;
//     startCountdown();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     TextTheme textTheme = Theme.of(context).textTheme;
//     return Obx(
//       () => InkWell(
//         onTap: countdownSeconds.value == 0 ? resendCode : null,
//         child: RichText(
//           text: TextSpan(
//             text: "resendText".tr,
//             style: textTheme.titleLarge!.copyWith(
//               color: AppColors.lightBlackColor,
//               fontSize: 18.sp,
//               height: 1.4,
//               fontWeight: FontWeight.w500,
//             ),
//             children: [
//               TextSpan(
//                 text: " ${countdownSeconds.value.toString()}s ",
//                 style: textTheme.titleLarge!.copyWith(
//                   color: AppColors.primaryColor,
//                   fontSize: 18.sp,
//                   height: 1.4,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
