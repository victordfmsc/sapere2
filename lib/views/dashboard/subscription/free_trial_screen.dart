import 'dart:io';

import 'package:sapere/views/dashboard/subscription/subscription_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constant/colors.dart';
import '../../../core/constant/images.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/primary_button.dart';

class FreeTrialScreen extends StatelessWidget {
  const FreeTrialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: Consumer<InAppPurchaseProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final weekly = provider.weeklyPackage;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(Icons.cancel, color: AppColors.textColor),
                    ),
                  ),
                  Image.asset(AppImagesUrls.logo, height: 200.h),
                  20.verticalSpace,
                  Text(
                    "enjoyPersonalizedAudiobooks".tr,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  10.verticalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textColor,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      "freeTrailWeek".tr,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  30.verticalSpace,
                  _buildPoint("createFirstBookFee".tr),
                  _buildPoint("fullAccessFeatures".tr),
                  _buildPoint("saveYourBooks".tr),
                  _buildPoint("youCanCancel".tr),
                  30.verticalSpace,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "afterFreeTrail".tr,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  10.verticalSpace,
                  _buildInfoRow(
                    Icons.calendar_today,
                    '1 ${'personalizedAudiobook'.tr} ${'weekly'.tr.length >= 4 ? 'weekly'.tr.substring(0, 4) : 'weekly'.tr}',
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    weekly?.storeProduct.priceString == null
                        ? '0.99/${'weekly'.tr}'
                        : '${weekly?.storeProduct.priceString}/${'weekly'.tr}',
                  ),
                  const Spacer(),
                  PrimaryButton(
                    onTap: () async {
                      showLoadingDialog(context, message: 'PleaseWait'.tr);
                      final success = await provider.buySubscription(weekly!);
                      Navigator.of(context).pop();

                      if (success) {
                        await provider.resetCurrentUserCreditsTo(1, context);
                        Get.snackbar(
                          'successful'.tr,
                          'subscription'.tr,
                          colorText: AppColors.textColor,
                        );
                        FirebaseAnalytics.instance.logPurchase(
                          currency: weekly.storeProduct.currencyCode,
                          value: weekly.storeProduct.price,
                          items: [
                            AnalyticsEventItem(
                              itemName: weekly.storeProduct.title,
                              itemId: weekly.storeProduct.identifier,
                              price: weekly.storeProduct.price,
                              quantity: 1,
                            ),
                          ],
                          transactionId:
                              'txn_${DateTime.now().millisecondsSinceEpoch}',
                          affiliation:
                              Platform.isAndroid ? 'Play Store' : 'Apple Store',
                          parameters: {
                            'user_id':
                                FirebaseAuth.instance.currentUser?.uid ??
                                'unknown_user',
                            'subscription_plan': 'weekly',
                            'timestamp': DateTime.now().toIso8601String(),
                          },
                        );

                        Navigator.of(context).pop();
                      } else {
                        Get.snackbar(
                          'warningImage'.tr,
                          'wentWrong'.tr,
                          colorText: AppColors.textColor,
                        );
                      }
                    },
                    text: 'startFreeTrail'.tr,
                    textColor: Colors.black,
                    bgColor: AppColors.textColor,
                  ),
                  40.verticalSpace,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: AppColors.textColor, size: 20),
          10.horizontalSpace,
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textColor, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textColor, size: 20),
          10.horizontalSpace,
          Text(
            text,
            style: TextStyle(color: AppColors.textColor, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
