import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/services/local_storage_service.dart';

class BottomSheetContent extends StatefulWidget {
  const BottomSheetContent({super.key});

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  String? codeLang;
  String? languageName;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    if (storedLang != null) {
      setState(() {
        codeLang = storedLang;
        languageName = getLanguageName(storedLang);
      });
    } else {
      setState(() {
        codeLang = 'en_US';
        languageName = getLanguageName('en_US');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('language code is $codeLang');
    if (codeLang == null) {
      return const Center(child: CircularProgressIndicator());
    }

    print('language code is $codeLang');

    return Consumer<InAppPurchaseProvider>(
      builder: (context, inAppProvider, child) {
        return Consumer<BukBukProvider>(
          builder: (context, provider, child) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.blackColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(
                  color: AppColors.textColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child:
                  provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, right: 8),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.whiteColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          if (inAppProvider.isSubscribed &&
                              inAppProvider.canPost == false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'youhaveused'.tr,
                                style: TextStyle(color: AppColors.whiteColor),
                              ),
                            ),
                          if (provider.sapereCategoryTypes.isNotEmpty)
                            SizedBox(
                              height: 60.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                separatorBuilder:
                                    (context, index) => SizedBox(width: 10.w),
                                itemCount: provider.sapereCategoryTypes.length,
                                itemBuilder: (context, index) {
                                  final category =
                                      provider.sapereCategoryTypes[index];
                                  bool isSelected =
                                      provider.categoryDocId == category.docId;

                                  return Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        provider.setCategoryDocId(
                                          category.docId,
                                        );
                                        provider.bukBukCategoryModel = category;
                                        provider.fetchDiaryTypes(
                                          category.docId,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 18.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? AppColors.textColor
                                                      .withOpacity(0.15)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? AppColors.textColor
                                                    : Colors.white.withOpacity(
                                                      0.2,
                                                    ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          category.names[codeLang] ??
                                              category.names['en_US'] ??
                                              'Category',
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? AppColors.textColor
                                                    : Colors.white60,
                                            fontSize: 14.sp,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                'noDataFound'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child:
                                provider.isTypesLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : provider.sapereTypes.isEmpty
                                    ? Center(
                                      child: Text(
                                        'noDataFound'.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          8.0,
                                        ).copyWith(bottom: 30),
                                        child: Wrap(
                                          children:
                                              provider.sapereTypes.map((
                                                sapereType,
                                              ) {
                                                final name =
                                                    sapereType
                                                        .names[codeLang] ??
                                                    'No Name';
                                                final description =
                                                    sapereType
                                                        .descriptions[codeLang] ??
                                                    'No Description';
                                                final url = sapereType.photoUrl;
                                                return customItemWidget(
                                                  name,
                                                  description,
                                                  url,
                                                  () {
                                                    final isSubscribed =
                                                        inAppProvider
                                                            .isSubscribed;
                                                    final canPost =
                                                        inAppProvider.canPost;

                                                    if (!isSubscribed) {
                                                      Get.snackbar(
                                                        'warningImage'.tr,
                                                        'You are not a premium user'
                                                            .tr,
                                                        backgroundColor:
                                                            Colors.red,
                                                        colorText:
                                                            AppColors.textColor,
                                                      );
                                                      Navigator.pushNamed(
                                                        context,
                                                        Routes.subscriptionPage,
                                                      );
                                                      return;
                                                    }

                                                    if (isSubscribed &&
                                                        !canPost!) {
                                                      Get.snackbar(
                                                        'warningImage'.tr,
                                                        'youhaveused'.tr,
                                                        backgroundColor:
                                                            Colors.red,
                                                        colorText:
                                                            AppColors.textColor,
                                                      );
                                                      return;
                                                    }

                                                    provider.bukBukTypeModel =
                                                        sapereType;
                                                    provider.setSelectedCover(
                                                      '',
                                                    );
                                                    Navigator.pushNamed(
                                                      context,
                                                      Routes.addBukBukPage,
                                                    );
                                                  },
                                                  sapereType.isProOnly,
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
            );
          },
        );
      },
    );
  }
}

Widget customItemWidget(
  String name,
  String description,
  String icon,
  VoidCallback onTap,
  bool isPro,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.textColor.withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: icon,
                    height: 70.h,
                    width: 60.w,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Skeletonizer(
                          enabled: true,
                          child: Container(
                            height: 70.h,
                            width: 60.w,
                            color: Colors.white10,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 70.h,
                          width: 60.w,
                          color: Colors.grey[900],
                          child: Icon(Icons.image, color: Colors.white24),
                        ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (isPro) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 2.h,
                              horizontal: 8.w,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.textColor,
                                  AppColors.kSamiOrange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textColor.withOpacity(0.5),
                size: 16.sp,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
