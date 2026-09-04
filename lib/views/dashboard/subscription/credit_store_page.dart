import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/views/dashboard/subscription/widgets/credit_packs_section.dart';

class CreditStorePage extends StatelessWidget {
  const CreditStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                children: [
                  Consumer<InAppPurchaseProvider>(
                    builder:
                        (context, provider, child) =>
                            _buildBalanceCard(provider),
                  ),
                  20.verticalSpace,
                  const CreditPacksSection(showHeader: false),
                  20.verticalSpace,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textColor,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'creditStoreTitle'.tr,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(InAppPurchaseProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGoldGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'yourBalance'.tr,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${provider.totalCredits}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              8.horizontalSpace,
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  'saperePoints'.tr,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
