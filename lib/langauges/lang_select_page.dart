import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/models/langauage.dart';
import 'package:sapere/providers/language_provider.dart';
import 'package:sapere/widgets/my_language.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/providers/gamification_provider.dart';
import 'package:wheel_chooser/wheel_chooser.dart';

class LanguageSelectPage extends StatefulWidget {
  const LanguageSelectPage({super.key});

  @override
  State<LanguageSelectPage> createState() => _LanguageSelectPageState();
}

class _LanguageSelectPageState extends State<LanguageSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: GetBuilder<LanguageController>(
        init: LanguageController(),
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 30.h),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
                ),
              ),
              SizedBox(height: 30.h),
              Center(
                child: Image.asset(AppImagesUrls.leafLogoIcon, height: 120.h),
              ),
              SizedBox(height: 40.h),
              Text(
                'selectLanguage'.tr,
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.textColor,
                ),
              ),
              SizedBox(
                height: Get.height * 0.40,
                width: Get.width * 0.7,
                child: WheelChooser.custom(
                  squeeze: 1.0,
                  onValueChanged: (a) {
                    controller.updateLanguageSelection(a);
                  },
                  isInfinite: true,
                  perspective: 0.005,
                  magnification: 1.0,
                  startPosition: controller.selectValue,
                  children: List.generate(langList.length, (index) {
                    return MySelectLanguage(
                      image: langList[index].image,
                      text: langList[index].langName,
                      color:
                          controller.selectValue == index
                              ? AppColors.whiteColor
                              : AppColors.blackColor50,
                      textColor:
                          controller.selectValue == index
                              ? AppColors.blackColor
                              : AppColors.textColor,
                    );
                  }),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 26.h),
                child: PrimaryButton(
                  onTap: () async {
                    await controller.checkSaveLang();
                    if (mounted) {
                      Provider.of<GamificationProvider>(
                        context,
                        listen: false,
                      ).reloadSubjects();
                    }
                    Get.back<void>();
                  },
                  width: 300.w,
                  text: 'select'.trim().tr,
                  textColor: AppColors.whiteColor,
                  bgColor: AppColors.primaryColor,
                  borderRadius: 100.r,
                  fontSize: 16.sp,
                  height: 62.h,
                  elevation: 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
