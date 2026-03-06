// // ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_function_literals_in_foreach_calls
//
// import 'package:sapere/core/constant/colors.dart';
// import 'package:sapere/core/constant/images.dart';
// import 'package:sapere/providers/subscription_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:provider/provider.dart';
//
// import 'package:shimmer/shimmer.dart';
// import 'package:in_app_review/in_app_review.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class SettingView extends StatefulWidget {
//   const SettingView({super.key});
//
//   @override
//   State<SettingView> createState() => _SettingViewState();
// }
//
// class _SettingViewState extends State<SettingView>
//     with TickerProviderStateMixin {
//   AnimationController? _controller;
//   final GlobalKey<AnimatedListState> _listkey = GlobalKey<AnimatedListState>();
//
//   final InAppReview inAppReview = InAppReview.instance;
//
//   String version = '';
//
//   getAppVersion() async {
//     PackageInfo packageInfo = await PackageInfo.fromPlatform();
//     print('device info>>>>>>>>>>>>>');
//     print(packageInfo.appName);
//     print(packageInfo.buildNumber);
//
//     setState(() {
//       version = '${packageInfo.version}(${packageInfo.buildNumber})';
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     getAppVersion();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//
//     _controller!.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final TextTheme appTextStyle = Theme.of(context).textTheme;
//     return Consumer<InAppPurchaseProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             elevation: 0,
//             centerTitle: true,
//             systemOverlayStyle: SystemUiOverlayStyle(
//               systemNavigationBarColor:
//                   AppColors.primaryColor, // navigation bar color
//               statusBarColor: AppColors.primaryColor, // status bar color
//             ),
//             title: Shimmer.fromColors(
//               baseColor: Colors.black,
//               highlightColor: AppColors.halfWhiteColor,
//               loop: 2,
//               child: Text(
//                 'setting'.tr,
//                 style: appTextStyle.bodyLarge!.copyWith(fontSize: 25.sp),
//               ),
//             ),
//             actions: [
//               Align(
//                 alignment: Alignment.center,
//                 child: IconButton(
//                   onPressed: () {
//                   },
//                   icon: Icon(
//                     Icons.logout,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//               ),
//             ],
//             backgroundColor: Colors.transparent,
//           ),
//         );
//       },
//     );
//   }
//
// }
