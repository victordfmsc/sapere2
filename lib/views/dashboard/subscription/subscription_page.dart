import 'dart:io';

import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/custom_card.dart';
import 'package:sapere/widgets/dailogs/premium_success_dialog.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      parameters: {
        'screen': 'subscription_screen_view',
        'timestamp': DateTime.now().toIso8601String(),
      },
      name: 'subscription_screen',
    );

    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final weekly = provider.weeklyPackage;
        final monthly = provider.monthlyPackage;
        final yearly = provider.yearlyPackage;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SubscriptionHeaderTexts(),
                  SizedBox(height: 10.h),

                  buildSubscriptionOptionWeekly(
                    title: '${'sapere'.tr} ${'weekly'.tr}',
                    subTitle:
                        "1 ${'premiumPoint6'.tr} ${'weekly'.tr.length >= 4 ? 'weekly'.tr.substring(0, 4) : 'weekly'.tr}",

                    onTap: () async {
                      showLoadingDialog(context, message: 'PleaseWait'.tr);
                      final success = await provider.buySubscription(weekly!);
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Close loading dialog

                      if (success) {
                        Navigator.of(context).pop(); // Close paywall

                        // Show success dialog over the previous screen
                        Get.dialog(
                          const PremiumSuccessDialog(points: '1'),
                          barrierDismissible: true,
                          useSafeArea: false,
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
                      } else {
                        Get.snackbar(
                          'warningImage'.tr,
                          'wentWrong'.tr,
                          colorText: AppColors.textColor,
                        );
                      }
                    },
                    price:
                        '${weekly?.storeProduct.priceString ?? '---'}/${'weekly'.tr}',
                    // price: '\$0.99/Weekly',
                  ),

                  SizedBox(height: 10.h),

                  // if (Monthly != null)
                  buildSubscriptionOption(
                    title: '${'sapere'.tr} ${'monthly'.tr}',
                    subTitle: "10 ${'premiumPoint6'.tr} ${'month'.tr}",
                    onTap: () async {
                      showLoadingDialog(context, message: 'PleaseWait'.tr);
                      final success = await provider.buySubscription(monthly!);
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Close loading dialog

                      if (success) {
                        Navigator.of(context).pop(); // Close paywall

                        // Show success dialog over the previous screen
                        Get.dialog(
                          const PremiumSuccessDialog(points: '10'),
                          barrierDismissible: true,
                          useSafeArea: false,
                        );

                        FirebaseAnalytics.instance.logPurchase(
                          currency: monthly.storeProduct.currencyCode,
                          value: monthly.storeProduct.price,
                          items: [
                            AnalyticsEventItem(
                              itemName: monthly.storeProduct.title,
                              itemId: monthly.storeProduct.identifier,
                              price: monthly.storeProduct.price,
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
                            'subscription_plan': 'monthly',
                            'timestamp': DateTime.now().toIso8601String(),
                          },
                        );
                      } else {
                        Get.snackbar(
                          'warningImage'.tr,
                          'wentWrong'.tr,
                          colorText: AppColors.textColor,
                        );
                      }
                    },
                    price:
                        '${monthly?.storeProduct.priceString ?? '---'}/${'monthly'.tr}',
                    // price: '\$99.99/Yearly',
                  ),
                  SizedBox(height: 10.h),

                  // if (yearly != null)
                  buildSubscriptionOption(
                    title: '${'sapere'.tr} ${'yearly'.tr}',
                    subTitle: "55 ${'premiumPoint6'.tr} ${'year'.tr}",
                    onTap: () async {
                      showLoadingDialog(context, message: 'PleaseWait'.tr);
                      final success = await provider.buySubscription(yearly!);
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Close loading dialog

                      if (success) {
                        Navigator.of(context).pop(); // Close paywall

                        // Show success dialog over the previous screen
                        Get.dialog(
                          const PremiumSuccessDialog(points: '55'),
                          barrierDismissible: true,
                          useSafeArea: false,
                        );

                        FirebaseAnalytics.instance.logPurchase(
                          currency: yearly.storeProduct.currencyCode,
                          value: yearly.storeProduct.price,
                          items: [
                            AnalyticsEventItem(
                              itemName: yearly.storeProduct.title,
                              itemId: yearly.storeProduct.identifier,
                              price: yearly.storeProduct.price,
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
                            'subscription_plan': 'yearly',
                            'timestamp': DateTime.now().toIso8601String(),
                          },
                        );
                      } else {
                        Get.snackbar(
                          'warningImage'.tr,
                          'wentWrong'.tr,
                          colorText: AppColors.textColor,
                        );
                      }
                    },
                    price:
                        '${yearly?.storeProduct.priceString ?? '---'}/${'yearly'.tr}',
                    // price: '\$99.99/Yearly',
                  ),

                  const SubscriptionBottomTexts(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showLoadingDialog(BuildContext context, {String? message}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.textColor),
                const SizedBox(height: 16),
                Text(
                  message ?? "Loading...",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

class SubscriptionHeaderTexts extends StatelessWidget {
  const SubscriptionHeaderTexts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.cancel, color: AppColors.whiteColor, size: 40),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'upgradeToPremium'.tr,
            style: TextStyle(
              fontSize: 28.sp,
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'upgradeToPremiumDesc'.tr,
            style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
          ),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'everythingIncluded'.tr,
            style: TextStyle(
              fontSize: 19.sp,
              color: AppColors.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "• ✅ ${"premiumPoint1".tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "• ✅ ${"premiumPoint2".tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "• ✅ ${"premiumPoint3".tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "• ✅ ${"premiumPoint4".tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),

        // Align(
        //   alignment: Alignment.centerLeft,
        //   child: Padding(
        //     padding: const EdgeInsets.only(left: 6),
        //     child: Text(
        //       "• ✅ ${"premiumPoint5".tr}",
        //       style: TextStyle(
        //         fontSize: 17.sp,
        //         color: AppColors.textColor,
        //       ),
        //     ),
        //   ),
        // ),
        // Align(
        //   alignment: Alignment.centerLeft,
        //   child: Padding(
        //     padding: const EdgeInsets.only(left: 6),
        //     child: Text(
        //       "• ✅ ${"premiumPoint6".tr}",
        //       style: TextStyle(
        //         fontSize: 17.sp,
        //         color: AppColors.textColor,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class SubscriptionBottomTexts extends StatelessWidget {
  const SubscriptionBottomTexts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Text(
          'bothMonthlyYearly'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 19.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'youCanCancel'.tr,
          style: TextStyle(
            fontSize: 19.sp,
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        RichText(
          text: TextSpan(
            text: 'byContinuingYouAgree'.tr,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            children: [
              TextSpan(
                text: 'termsCondition'.tr,
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () async {
                        if (Platform.isIOS) {
                          String url =
                              "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
                          if (!await launchUrl(Uri.parse(url))) {
                            throw Exception('Could not launch $url');
                          }
                        } else {
                          Get.toNamed(Routes.termsConditionPage);
                        }
                      },
              ),
              TextSpan(
                text: 'and'.tr,
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              TextSpan(
                text: 'privacyPolicyText'.tr,
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () async {
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
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
