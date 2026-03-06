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
        actions: [
          IconButton(
            icon: Icon(Icons.bookmarks_rounded, color: AppColors.kSamiOrange),
            onPressed: () {
              Navigator.pushNamed(context, Routes.savedReels);
            },
            tooltip: "Guardados",
          ),
          SizedBox(width: 8.w),
        ],
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
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'noDataFound'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppColors.textColor,
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

                return postList.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(8.0).copyWith(top: 230.h),
                      child: Center(
                        child: Text(
                          'emptyPost'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 19.sp,
                          ),
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 34.h,
                      ).copyWith(bottom: 0, top: 8.h),
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: postList.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
