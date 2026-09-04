import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/utils/dialog_utils.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/views/dashboard/subscription/widgets/credit_packs_section.dart';
import 'package:sapere/views/dashboard/subscription/widgets/trial_timeline_widget.dart';
import 'package:sapere/widgets/dailogs/premium_success_dialog.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sapere/views/dashboard/stream/add_sapere/add_sapere_page.dart';

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
        final monthly = provider.monthlyPackage;
        final yearly = provider.yearlyPackage;
        final hasTrial = InAppPurchaseProvider.packageHasFreeTrial(yearly);
        String gainedPoints() =>
            (provider.lastPurchaseGain > 0 ? provider.lastPurchaseGain : 4)
                .toString();

        return Scaffold(
          body: Skeletonizer(
            enabled: provider.isLoading,
            child:
                provider.availablePackages == null ||
                        provider.availablePackages!.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.signal_wifi_off_rounded,
                            color: AppColors.textColor.withOpacity(0.5),
                            size: 64.sp,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'connectionLostTitle'.tr,
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 30.h),
                          ElevatedButton(
                            onPressed: () => provider.fetchOfferings(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.premiumGoldGradient.colors.first,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text('retryConnectionText'.tr),
                          ),
                        ],
                      ),
                    )
                    : SafeArea(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 60.h,
                                  ), // Space for persistent X
                                  if (hasTrial) ...[
                                    const TrialTimelineWidget(),
                                    SizedBox(height: 20.h),
                                  ],
                                  SubscriptionHeaderTexts(hasTrial: hasTrial),
                                  SizedBox(height: 15.h),

                                  // PREMIUM (ANUAL) - DESTACADO COMO MEJOR VALOR
                                  buildHighlightedOption(
                                    title: 'premiumPlanTitle'.tr,
                                    subTitle: 'creditsPerMonth'.tr,
                                    isBestValue: true,
                                    label:
                                        "${'savePercent'.tr} ${provider.annualSavingsPercentage}",
                                    hasTrial: hasTrial,
                                    onTap: () async {
                                      if (yearly == null) return;
                                      showLoadingDialog(
                                        context,
                                        message: 'PleaseWait'.tr,
                                      );
                                      final success = await provider
                                          .buySubscription(yearly);
                                      if (!mounted) return;
                                      Navigator.of(context).pop();

                                      if (success) {
                                        Navigator.of(context).pop();
                                        Get.dialog(
                                          PremiumSuccessDialog(
                                            points: gainedPoints(),
                                            onClose: () {
                                              Get.to(
                                                () => AddSaperePage(
                                                  initialText:
                                                      'unlockFirstDoc'.tr,
                                                ),
                                              );
                                            },
                                          ),
                                          barrierDismissible: true,
                                          useSafeArea: false,
                                        );
                                      }
                                    },
                                    price:
                                        '${yearly?.storeProduct.priceString ?? '---'}/${'yearly'.tr}',
                                  ),

                                  SizedBox(height: 15.h),

                                  // STANDARD (MENSUAL)
                                  buildSubscriptionOption(
                                    title: 'standardPlanTitle'.tr,
                                    subTitle: 'creditsPerMonth'.tr,
                                    isFeatured: true,
                                    onTap: () async {
                                      if (monthly == null) return;
                                      showLoadingDialog(
                                        context,
                                        message: 'PleaseWait'.tr,
                                      );
                                      final success = await provider
                                          .buySubscription(monthly);
                                      if (!mounted) return;
                                      Navigator.of(context).pop();

                                      if (success) {
                                        Navigator.of(context).pop();
                                        Get.dialog(
                                          PremiumSuccessDialog(
                                            points: gainedPoints(),
                                            onClose: () {
                                              Get.to(
                                                () => AddSaperePage(
                                                  initialText:
                                                      'unlockFirstDoc'.tr,
                                                ),
                                              );
                                            },
                                          ),
                                          barrierDismissible: true,
                                          useSafeArea: false,
                                        );
                                      }
                                    },
                                    price:
                                        '${monthly?.storeProduct.priceString ?? '---'}/${'monthly'.tr}',
                                  ),

                                  SizedBox(height: 20.h),

                                  // TIENDA DE CRÉDITOS (packs consumibles)
                                  const CreditPacksSection(),
                                  SizedBox(height: 10.h),

                                  const SubscriptionBottomTexts(),
                                  SizedBox(height: 30.h),
                                ],
                              ),
                            ),
                          ),
                          // PERSISTENT CLOSE BUTTON (2026 Strategy: Trust + Accessibility)
                          Positioned(
                            top: 10.h,
                            right: 20.w,
                            child: GestureDetector(
                              onTap:
                                  () => Get.offAllNamed(Routes.dashboardScreen),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textColor,
                                  size: 28.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }

  // --- 2026 NEW UI HELPERS ---

  Widget buildHighlightedOption({
    required String title,
    required String subTitle,
    required String price,
    required VoidCallback onTap,
    String label = "MOST POPULAR",
    bool isBestValue = true,
    bool hasTrial = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient:
              AppColors
                  .premiumGoldGradient, // LTV FOCUS: Dominant Gold Gradient
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.textColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isBestValue)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(14.r),
                          bottomLeft: Radius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors
                            .black, // Dark text on gold for premium readability
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subTitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        hasTrial ? 'startFreeTrail'.tr : 'subscribeNow'.tr,
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSubscriptionOption({
    required String title,
    required String subTitle,
    required String price,
    required VoidCallback onTap,
    bool isFeatured = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isFeatured
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isFeatured
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
            width: isFeatured ? 1.5 : 1,
          ),
          boxShadow:
              isFeatured
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isFeatured
                              ? AppColors.textColor
                              : AppColors.textColor.withOpacity(0.4),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subTitle,
                    style: TextStyle(
                      color:
                          isFeatured
                              ? AppColors.textColor.withOpacity(0.6)
                              : AppColors.textColor.withOpacity(0.2),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color:
                    isFeatured
                        ? AppColors.textColor
                        : AppColors.textColor.withOpacity(0.3),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionHeaderTexts extends StatelessWidget {
  final bool hasTrial;

  const SubscriptionHeaderTexts({super.key, this.hasTrial = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'paywallHeroTitle'.tr,
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
            'paywallHeroSubtitle'.tr,
            style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
          ),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'whatYouGet'.tr,
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
              "• ✨ ${'benefitAIPower'.tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              "• 🧠 ${'benefitEasyLearning'.tr}",
              style: TextStyle(fontSize: 17.sp, color: AppColors.textColor),
            ),
          ),
        ),
        if (hasTrial)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                "• 🌍 ${'wiselyText'.tr}",
                style: TextStyle(
                  fontSize: 18.sp,
                  color: AppColors.premiumGoldGradient.colors.first,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
