import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/database_helper.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/views/dashboard/stream/components/sapere_card.dart';
import 'package:sapere/views/dashboard/stream/stream.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constant/const.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  String? codeLang;
  String selectedLanguage = 'All';

  final db = DataBaseHelper();
  bool isLangLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    final lang = storedLang ?? 'en_US';

    setState(() {
      codeLang = lang;
      selectedLanguage = getLanguageName(lang);
      isLangLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sync with global locale if it changed
    final currentLocale = Get.locale?.toString() ?? 'en_US';
    if (isLangLoaded && codeLang != currentLocale) {
      Future.microtask(() {
        setState(() {
          codeLang = currentLocale;
          selectedLanguage = getLanguageName(currentLocale);
        });
      });
    }

    if (!isLangLoaded) {
      return Scaffold(
        backgroundColor: AppColors.blackColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        title: Text(
          'myCreation'.tr,
          style: TextStyle(color: AppColors.textColor),
        ),
        actions: [SizedBox(width: 8.w)],
      ),
      body: _buildCreationsTab(),
    );
  }

  Widget _buildCreationsTab() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(right: 8.w, top: 8.h),
            child: LanguageDropdown(
              languages: languageNames,
              selectedLanguage: selectedLanguage,
              onChanged: (lang) {
                setState(() {
                  selectedLanguage = lang;
                });
              },
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BukBukPost>?>(
            stream: getUserBukBukPostStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const BukBukLoadingWidget();
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 230.h),
                  child: Center(
                    child: SelectableText(
                      'An ${snapshot.error} occurred',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                );
              } else {
                List<BukBukPost> postList = snapshot.data!;

                if (selectedLanguage != 'All') {
                  postList =
                      postList
                          .where((post) => post.language == selectedLanguage)
                          .toList();
                }

                if (postList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(30.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.kGoldGradient[0].withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 80.sp,
                              color: AppColors.kGoldGradient[0],
                            ),
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            'beginYourLegacy'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textColor,
                              fontFamily: 'NotoSerifDisplay',
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'emptyCreationsSubtitle'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white60,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 40.h),
                          GestureDetector(
                            onTap: () {
                              Get.dialog(
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.all(24.w),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 32.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: AppColors.kGoldGradient[0],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Activation Tip'.tr,
                                          style: TextStyle(
                                            color: AppColors.kGoldGradient[0],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          'Tap the "+" button in the center of the menu to create your first Sapere!'
                                              .tr,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.kGoldGradient,
                                ),
                                borderRadius: BorderRadius.circular(30.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.kGoldGradient[0]
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                'createFirstSapere'.tr.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.sp,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 34.h,
                  ).copyWith(bottom: 0, top: 8.h),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: postList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    BukBukPost post = postList[index];
                    bool isGenerating =
                        post.sapereUrl == null || post.sapereUrl!.isEmpty;
                    return SapereCard(
                      imageUrl: post.newCover.toString(),
                      title: post.sapereName ?? 'Sapere',
                      isGenerating: isGenerating,
                      onTap:
                          isGenerating
                              ? () {
                                Get.snackbar(
                                  'info'.tr,
                                  'generatingText'.tr,
                                  backgroundColor: AppColors.primaryColor,
                                  colorText: AppColors.whiteColor,
                                );
                              }
                              : () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.sapereDetails,
                                  arguments: post,
                                );
                              },
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Stream<List<BukBukPost>?> getUserBukBukPostStream() {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var stream =
          db.postCollection
              .orderBy('publishTime', descending: true)
              .where('uId', isEqualTo: uid)
              .snapshots();

      return stream.map((snapshot) {
        return snapshot.docs
            .map((e) => e.data()!)
            .where((post) => post.type != 'preview')
            .toList();
      });
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), colorText: AppColors.textColor);
      return Stream.value([]);
    }
  }
}
