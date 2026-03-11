import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sapere/widgets/sapere_image.dart';

import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/firestore_collection.dart';
import 'package:sapere/models/sapere_category_type_model.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/core/constant/const.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<BukBukCategoryModel> _categories = [];
  List<BukBukPost> _posts = [];
  bool _isLoading = true;
  String? selectedLanguage = 'All';
  bool isLangLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  String? codeLang;

  Future<void> _loadLanguage() async {
    final lang = Get.locale?.toString() ?? 'en_US';

    setState(() {
      codeLang = lang;
      isLangLoaded = true;
      print('CategoriesScreen: Selected language code is $codeLang');
    });
    fetchData();
  }

  // The duplicate declaration of selectedLanguage is removed.
  // The original `String? selectedLanguage = 'All';` at the top of the class is retained.

  Future<void> fetchData() async {
    try {
      final categoriesSnapshot =
          await FirebaseFirestore.instance
              .collection(sapereTypeCategoriesCollection)
              .get();

      final categories =
          categoriesSnapshot.docs
              .map((doc) => BukBukCategoryModel.fromFirestore(doc))
              .toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      // Get the correct language name for filtering (e.g., 'Spanish (Spain)')
      final String languageName = getLanguageName(codeLang ?? 'en_US');

      // Fetch posts for each category one by one and update UI as they arrive
      for (var category in categories) {
        final postsSnapshot =
            await FirebaseFirestore.instance
                .collection(sapereCollection)
                .where('bukbukCategoryId', isEqualTo: category.docId)
                .where('language', isEqualTo: languageName)
                .limit(15)
                .get();

        final posts =
            postsSnapshot.docs
                .map((doc) => BukBukPost.fromFirestore(doc))
                .toList();

        if (mounted) {
          setState(() {
            _posts.addAll(posts);
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if locale changed since last load
    final currentLocale = Get.locale?.toString() ?? 'en_US';
    if (isLangLoaded && codeLang != currentLocale) {
      Future.microtask(() => _loadLanguage());
    }

    if (!isLangLoaded) {
      return const Scaffold(body: CategoriesLoadingWidget(length: 3));
    }
    if (_isLoading) {
      return const Scaffold(body: CategoriesLoadingWidget(length: 3));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'categories'.tr,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body:
          _categories.isEmpty
              ? Center(child: Text('noDataFound'.tr))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];

                        final bukbukInCategory =
                            _posts
                                .where(
                                  (post) =>
                                      post.sapereCategoryId == category.docId,
                                )
                                .toList();

                        String displayCategoryName = 'No Name';
                        if (category.names.isNotEmpty) {
                          final lang = codeLang ?? 'en_US';
                          final shortLang = lang.split('_').first;

                          displayCategoryName =
                              category.names[lang] ??
                              category.names[shortLang] ??
                              category.names['en_US'] ??
                              category.names['en'] ??
                              category.names['es_ES'] ??
                              category.names['es'] ??
                              category.names.values.first;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 18.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.textColor,
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    displayCategoryName,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (bukbukInCategory.isEmpty)
                              SizedBox(
                                height: 200.h,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textColor
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'loading'.tr,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 300.h,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  separatorBuilder:
                                      (context, index) => SizedBox(width: 14.w),
                                  itemCount: bukbukInCategory.length,
                                  itemBuilder: (context, bukbukIndex) {
                                    final bukbuk =
                                        bukbukInCategory[bukbukIndex];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.sapereDetails,
                                          arguments: bukbuk,
                                        );
                                      },
                                      child: Container(
                                        width: 150.w,
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.textColor
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                child: SapereImage(
                                                  imageUrl:
                                                      bukbuk.newCover ?? "",
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.w),
                                              child: Text(
                                                bukbuk.sapereName ?? 'No Name',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class CategoriesLoadingWidget extends StatelessWidget {
  final int length;
  const CategoriesLoadingWidget({super.key, required this.length});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24.h,
                  width: 160.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  margin: EdgeInsets.only(bottom: 16.h),
                ),
                SizedBox(
                  height: 250.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => SizedBox(width: 14.w),
                    itemBuilder:
                        (_, i) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 180.h,
                              width: 130.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              height: 14.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              height: 14.h,
                              width: 80.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
