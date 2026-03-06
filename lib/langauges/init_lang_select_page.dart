import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/models/langauage.dart';
import 'package:sapere/providers/language_provider.dart';
import 'package:sapere/views/onboarding/intro_screen.dart';
import 'package:sapere/widgets/my_language.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wheel_chooser/wheel_chooser.dart';

class InitLanguageSelectPage extends StatefulWidget {
  const InitLanguageSelectPage({super.key});

  @override
  State<InitLanguageSelectPage> createState() => _InitLanguageSelectPageState();
}

class _InitLanguageSelectPageState extends State<InitLanguageSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<LanguageController>(
        init: LanguageController(),
        builder: (controller) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 120.h),
              Center(child: Image.asset(AppImagesUrls.logo, height: 120.h)),
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
                    controller.selectValue = a;
                    controller.languageModel = langList[a];

                    print(
                      "${controller.languageModel.locale}_${controller.languageModel.langCode}",
                    );
                    controller.update();
                  },
                  isInfinite: true,
                  perspective: 0.005,
                  magnification: 1.0,
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
                //
              ),
              Padding(
                padding: EdgeInsets.only(top: 26.h),
                child: PrimaryButton(
                  onTap: () async {
                    controller.checkSaveLang().then((value) {
                      Get.offAll(() => const OnBoardingScreen());
                    });
                  },
                  width: 300.w,
                  text: 'select'.tr,
                  textColor: AppColors.textColor,
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
