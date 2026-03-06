import 'dart:io';

import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/utils/utils.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/widgets/dailogs/logout_dialog.dart';
import 'package:sapere/widgets/drawer_item.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawerScreen extends StatefulWidget {
  final String version;
  const CustomDrawerScreen({super.key, required this.version});

  @override
  State<CustomDrawerScreen> createState() => _CustomDrawerScreenState();
}

class _CustomDrawerScreenState extends State<CustomDrawerScreen> {
  final InAppReview inAppReview = InAppReview.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: ListTileTheme(
            textColor: Colors.white,
            iconColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.only(left: 20.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      AppImagesUrls.leafLogoIcon,
                      width: double.infinity.w,
                      height: 100.h,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.ProfileBrown,
                    title: 'profile'.tr,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.profileScreen);
                    },
                    isDrawer: true,
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.languageIcon,
                    title: 'language'.tr,
                    isDrawer: true,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.languageScreen);
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.privacyIcon,
                    isDrawer: true,
                    title: 'reUsableListTitle4'.tr,
                    onTap: () async {
                      if (Platform.isIOS) {
                        String url =
                            'https://patagoniadelhi.com/saperes-refund-cancellation-and-legal-information-policy/';
                        if (!await launchUrl(Uri.parse(url))) {
                          throw Exception('Could not launch $url');
                        }
                      } else {
                        Get.toNamed(Routes.termsConditionPage);
                      }
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.termsConditionIcon,
                    isDrawer: true,
                    title: 'termsCondition'.tr,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.termsConditionPage);
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.contactsIcon,
                    isDrawer: true,
                    title: 'contactUs'.tr,
                    onTap: () {
                      launchMailto();
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.rateUsIcon,
                    isDrawer: true,
                    title: 'rateTheApp'.tr,
                    onTap: () {
                      inAppReview.openStoreListing(appStoreId: '6745130037');
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.restoreIcon,
                    isDrawer: true,
                    title: 'restorePurchase'.tr,
                    onTap: () {
                      provider.restorePurchases();
                    },
                  ),
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.deleteIcon,
                    isDrawer: true,
                    title: 'deleteAccount'.tr,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.accountDeletion);
                    },
                  ),
                  if (!provider.isSubscribed) ...[
                    SizedBox(height: 15.h),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, Routes.subscriptionPage);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.kGoldGradient,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.kSamiOrange.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stars_rounded, color: Colors.black),
                            SizedBox(width: 12.w),
                            Text(
                              'upgradeToPremium'.tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 15.h),
                  DrawerCard(
                    svgIcon: AppImagesUrls.languageIcon,
                    isDrawer: true,
                    isSvg: true,
                    iconData: Icons.logout,
                    title: 'logoutTitle'.tr,
                    onTap: () {
                      Get.dialog(const LogOutDialog());
                    },
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      '${'appVersion'.tr} ${widget.version}',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Future<void> copyFirestoreData() async {
  //   CollectionReference sourceRef =
  //   FirebaseFirestore.instance.collection("diaryTypes");
  //   CollectionReference destRef =
  //   FirebaseFirestore.instance.collection("dairyTypeCategories");
  //
  //   QuerySnapshot snapshot = await sourceRef.get();
  //
  //   List<Future> tasks = [];
  //
  //   for (QueryDocumentSnapshot doc in snapshot.docs) {
  //     String docId = doc.id;
  //     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //
  //     tasks.add(destRef
  //         .doc("MRuXCKLEXKJiBVRWDTCw")
  //         .collection("dairyTypes")
  //         .doc(docId)
  //         .set(data));
  //   }
  //
  //   await Future.wait(tasks);
  //   print("Data copied successfully!");
  // }
}
