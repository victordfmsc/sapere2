import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/utils/dialog_utils.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sapere/widgets/dailogs/premium_success_dialog.dart';
import 'package:sapere/views/dashboard/stream/add_sapere/add_sapere_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class FreeTrialScreen extends StatefulWidget {
  const FreeTrialScreen({super.key});

  @override
  State<FreeTrialScreen> createState() => _FreeTrialScreenState();
}

class _FreeTrialScreenState extends State<FreeTrialScreen> {
  PackageType _selectedType = PackageType.weekly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: Consumer<InAppPurchaseProvider>(
          builder: (context, provider, child) {
            final yearly = provider.yearlyPackage;
            final monthly = provider.monthlyPackage;
            final weekly = provider.weeklyPackage;

            final selectedPackage =
                (_selectedType == PackageType.monthly)
                    ? monthly
                    : (_selectedType == PackageType.annual ? yearly : weekly);

            return Skeletonizer(
              enabled: provider.isLoading,
              child:
                  (yearly == null && weekly == null && monthly == null) &&
                          !provider.isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.textColor.withOpacity(0.5),
                              size: 64.sp,
                            ),
                            20.verticalSpace,
                            Text(
                              'connectionLostTitle'.tr,
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            10.verticalSpace,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.w),
                              child: PrimaryButton(
                                onTap: () => provider.fetchOfferings(),
                                text: 'retryConnectionText'.tr,
                                bgColor: AppColors.textColor,
                                textColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 10.h,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  20.verticalSpace,
                                  Image.asset(AppImagesUrls.logo, height: 45.h),
                                  20.verticalSpace,
                                  Text(
                                    'paywallHeroTitle'.tr,
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  8.verticalSpace,
                                  Text(
                                    'paywallHeroSubtitle'.tr,
                                    style: TextStyle(
                                      color: AppColors.textColor.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  30.verticalSpace,
                                  // Main Focus: Weekly
                                  if (weekly != null)
                                    _buildPlanCard(
                                      title: 'weeklyPlanTitle'.tr,
                                      price: weekly.storeProduct.priceString,
                                      isSelected:
                                          _selectedType == PackageType.weekly,
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedType =
                                                    PackageType.weekly,
                                          ),
                                      badge: 'startFreeTrail'.tr,
                                      isHighlight: true,
                                      subtext: 'afterFreeTrail'.tr,
                                    ),
                                  16.verticalSpace,
                                  // Secondary Mini Options
                                  Row(
                                    children: [
                                      if (monthly != null)
                                        Expanded(
                                          child: _buildMiniPlanCard(
                                            title: 'monthlyPlanTitle'.tr,
                                            price:
                                                monthly
                                                    .storeProduct
                                                    .priceString,
                                            isSelected:
                                                _selectedType ==
                                                PackageType.monthly,
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      _selectedType =
                                                          PackageType.monthly,
                                                ),
                                          ),
                                        ),
                                      if (monthly != null && yearly != null)
                                        12.horizontalSpace,
                                      if (yearly != null)
                                        Expanded(
                                          child: _buildMiniPlanCard(
                                            title: 'yearlyPlanTitle'.tr,
                                            price:
                                                yearly.storeProduct.priceString,
                                            isSelected:
                                                _selectedType ==
                                                PackageType.annual,
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      _selectedType =
                                                          PackageType.annual,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  40.verticalSpace,
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.r),
                                      gradient:
                                          _selectedType == PackageType.weekly
                                              ? AppColors.premiumGoldGradient
                                              : null,
                                      color:
                                          _selectedType == PackageType.weekly
                                              ? null
                                              : AppColors.textColor,
                                    ),
                                    child: PrimaryButton(
                                      onTap: () async {
                                        if (selectedPackage == null) return;
                                        showLoadingDialog(
                                          context,
                                          message: 'PleaseWait'.tr,
                                        );
                                        final success = await provider
                                            .buySubscription(selectedPackage);
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();

                                        if (success) {
                                          Get.dialog(
                                            PremiumSuccessDialog(
                                              points:
                                                  _selectedType ==
                                                          PackageType.annual
                                                      ? '55'
                                                      : (_selectedType ==
                                                              PackageType
                                                                  .monthly
                                                          ? '10'
                                                          : '1'),
                                              onClose: () {
                                                Get.offAllNamed(
                                                  Routes.dashboardScreen,
                                                );
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
                                        } else {
                                          Get.snackbar(
                                            'warningImage'.tr,
                                            'wentWrong'.tr,
                                            colorText: AppColors.textColor,
                                          );
                                        }
                                      },
                                      text:
                                          _selectedType == PackageType.weekly
                                              ? 'startFreeTrail'.tr
                                              : 'upgradeToPremiumBtn'.tr,
                                      textColor: Colors.black,
                                      bgColor:
                                          _selectedType == PackageType.weekly
                                              ? Colors.transparent
                                              : AppColors.textColor,
                                    ),
                                  ),
                                  20.verticalSpace,
                                ],
                              ),
                            ),
                          ),
                          // Close Button
                          Positioned(
                            top: 10.h,
                            right: 20.w,
                            child: GestureDetector(
                              onTap:
                                  () => Get.offAllNamed(Routes.dashboardScreen),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniPlanCard({
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.textColor.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.textColor : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.textColor : Colors.white70,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            2.verticalSpace,
            Text(
              price,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
    required String badge,
    bool isHighlight = false,
    String? subtext,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.black,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color:
                isSelected
                    ? (isHighlight
                        ? const Color(0xFFFFD700)
                        : AppColors.textColor)
                    : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? (isHighlight
                            ? AppColors.kSamiOrange
                            : AppColors.textColor.withOpacity(0.2))
                        : Colors.white10,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            14.verticalSpace,
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            6.verticalSpace,
            Text(
              price,
              style: TextStyle(
                color: isHighlight ? const Color(0xFFFFD700) : Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtext != null) ...[
              6.verticalSpace,
              Text(
                subtext,
                style: TextStyle(
                  color: AppColors.kSamiOrange,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
