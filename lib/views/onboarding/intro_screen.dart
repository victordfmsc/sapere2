import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/routes/app_pages.dart';
import 'widgets/onboarding_card.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => OnBoardingVm(),
      child: Consumer<OnBoardingVm>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: AppColors.blackColor,
            body: Stack(
              children: [
                // Mysterious Background Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0F172A), // Deep Navy
                          AppColors.blackColor,
                        ],
                      ),
                    ),
                  ),
                ),
                // Subtle overlay pattern/noise (simulated with a lighter gradient)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          const Color(0xFF1E293B).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                PageView.builder(
                  controller: vm.pageController,
                  itemCount: vm.contents.length,
                  onPageChanged: (int index) {
                    vm.setIndex(index);
                  },
                  itemBuilder: ((context, index) {
                    var data = vm.contents[index];
                    return IntroWidget(
                      name: data.name,
                      image: data.image,
                      index: index,
                      description: data.description,
                      onSkipTap: () {
                        vm.onIntroEnd(context);
                      },
                      onContinueTap: () {
                        vm.onNextTap(context);
                      },
                      primaryColor: AppColors.primaryColor,
                      secondary: AppColors.textColor,
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnBoardingVm extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  setIndex(int index) {
    currentPage = index;
    notifyListeners();
  }

  void onNextTap(BuildContext context) {
    if (pageController.page != null) {
      final nextPage = pageController.page! + 1;
      if (nextPage < contents.length) {
        pageController.animateToPage(
          nextPage.toInt(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      } else {
        onIntroEnd(context);
      }
    }
  }

  Future<void> onIntroEnd(context) async {
    await LocalStorage().setIsFirstTime(value: false);
    Navigator.pushReplacementNamed(context, Routes.signInScreen);
  }

  List<OnBoardingModel> contents = [
    OnBoardingModel(
      name: 'onBoardingTitle1'.tr,
      image: AppImagesUrls.onb1,
      description: 'onBoardingDescription1'.tr,
    ),
    OnBoardingModel(
      name: 'onBoardingTitle2'.tr,
      image: AppImagesUrls.onb2,
      description: 'onBoardingDescription2'.tr,
    ),
    OnBoardingModel(
      name: 'onBoardingTitle3'.tr,
      image: AppImagesUrls.onb3,
      description: 'onBoardingDescription3'.tr,
    ),
  ];
}

class OnBoardingModel {
  String image;
  String name;
  String description;

  OnBoardingModel({
    required this.image,
    required this.name,
    required this.description,
  });
}
