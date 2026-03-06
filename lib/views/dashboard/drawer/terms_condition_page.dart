// ignore_for_file: must_be_immutable

import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class TermsConditionPage extends StatelessWidget {
  TermsConditionPage({super.key});

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'termsCondition'.tr,
          style: appTextStyle.displayMedium!.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: AppColors.textColor),
        ),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primaryColor,
                thumbColor: AppColors.primaryColor,
                thumbShape: SliderComponentShape.noThumb,
              ),
              child: Scrollbar(
                controller: scrollController,
                child: ListView(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.vertical,
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 13.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "instruction".tr,
                            style: appTextStyle.displayMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 30.sp,
                                color: AppColors.textColor),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'termsService'.tr,
                            textAlign: TextAlign.center,
                            style: appTextStyle.displayMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 30.sp,
                                color: AppColors.textColor),
                          ),
                          SizedBox(height: 12.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: policyList.map((e) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0)
                                    .copyWith(left: 0, right: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e['title'],
                                        style:
                                            appTextStyle.titleMedium!.copyWith(
                                          color: AppColors.textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18.sp,
                                        )),
                                    SizedBox(height: 10.h),
                                    Padding(
                                      padding: EdgeInsets.only(left: 34.w),
                                      child: Text(e['subTitle'],
                                          style: appTextStyle.titleMedium!
                                              .copyWith(
                                            color: AppColors.textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.sp,
                                          )),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  List<Map<String, dynamic>> policyList = [
    {
      'title': 'introTitle'.tr,
      'subTitle': 'introTermsSubTitle'.tr,
    },
    {
      'title': 'desServiceTitleText'.tr,
      'subTitle': 'infoSubTitleText'.tr,
    },
    {
      'title': 'userAccountTitleText'.tr,
      'subTitle': 'userAccountSubText'.tr,
    },
    {
      'title': 'aiGeneratedTitleText'.tr,
      'subTitle': 'aiGeneratedSubText'.tr,
    },
    {
      'title': 'userContentTitleText'.tr,
      'subTitle': 'userContentSubText'.tr,
    },
    {
      'title': 'PrivacyTitleText'.tr,
      'subTitle': 'privacySubText'.tr,
    },
    {
      'title': 'changesServiceTitleText'.tr,
      'subTitle': 'changesServiceSubText'.tr,
    },
    {
      'title': 'LimitationTitleText'.tr,
      'subTitle': 'LimitationSubText'.tr,
    },
    {
      'title': 'JurisdictionTitleText'.tr,
      'subTitle': 'JurisdictionSubText'.tr,
    },
    {
      'title': 'agreeAbideTitleText'.tr,
      'subTitle': 'agreeAbideSubText'.tr,
    }
  ];
}
