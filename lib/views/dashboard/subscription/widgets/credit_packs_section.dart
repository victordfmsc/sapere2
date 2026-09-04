import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/utils/dialog_utils.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Packs de créditos consumibles con el saldo actual. Se usa dentro del
/// paywall y en la tienda de créditos.
class CreditPacksSection extends StatelessWidget {
  const CreditPacksSection({super.key, this.showHeader = true});

  /// Muestra el título "Comprar créditos" y el saldo a la derecha.
  final bool showHeader;

  /// `credits_pack_5` -> 5, `credits_pack_15` -> 15, `credits_pack_40` -> 40.
  static int creditsFor(StoreProduct product) {
    final match = RegExp(r'(\d+)').firstMatch(product.identifier);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  Future<void> _buy(
    BuildContext context,
    InAppPurchaseProvider provider,
    StoreProduct product,
  ) async {
    showLoadingDialog(context, message: 'PleaseWait'.tr);
    final success = await provider.buyCreditPack(product);
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (success) {
      Get.snackbar(
        'successful'.tr,
        'creditPackPurchased'.tr,
        colorText: AppColors.textColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        final packs = provider.creditPacks;
        final loading = provider.isLoadingPacks;
        final unavailable = packs.isEmpty && !loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[_buildHeader(provider), 12.verticalSpace],
            if (unavailable)
              _buildUnavailable(provider)
            else ...[
              Skeletonizer(
                enabled: loading,
                child: Column(
                  children: [
                    if (packs.isEmpty)
                      for (var i = 0; i < 3; i++)
                        _buildCard(context, provider, null)
                    else
                      for (final product in packs)
                        _buildCard(context, provider, product),
                  ],
                ),
              ),
              Center(
                child: Text(
                  'creditsNeverExpire'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.6),
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(InAppPurchaseProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'buyCredits'.tr,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: AppColors.premiumGoldGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '${'yourBalance'.tr}: ${provider.totalCredits}',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    InAppPurchaseProvider provider,
    StoreProduct? product,
  ) {
    final credits = product == null ? 0 : creditsFor(product);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.title ?? 'creditStoreTitle'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'creditPackSubtitle'.trParams({'n': '$credits'}),
                    style: TextStyle(
                      color: AppColors.textColor.withOpacity(0.6),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            12.horizontalSpace,
            PrimaryButton(
              onTap:
                  product == null
                      ? () {}
                      : () => _buy(context, provider, product),
              text: product?.priceString ?? '---',
              width: 110.w,
              height: 40.h,
              fontSize: 13.sp,
              borderRadius: 12,
              textColor: Colors.black,
              bgColor: AppColors.textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailable(InAppPurchaseProvider provider) {
    final failed = provider.creditPacksFailed;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.storefront_outlined,
            color: AppColors.textColor.withOpacity(0.5),
            size: 36.sp,
          ),
          10.verticalSpace,
          Text(
            (failed ? 'connectionLostTitle' : 'creditPacksUnavailable').tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textColor.withOpacity(0.8),
              fontSize: 14.sp,
            ),
          ),
          6.verticalSpace,
          TextButton(
            onPressed: () {
              provider.fetchCreditPacks();
              provider.refreshCredits(invalidate: true);
            },
            child: Text(
              'retryConnectionText'.tr,
              style: TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
