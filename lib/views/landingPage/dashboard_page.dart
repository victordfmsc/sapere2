import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:sapere/animation/auto_shake_animation.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/tutorial_service.dart';
import 'package:sapere/providers/subscription_provider.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/views/dashboard/categories/categories_screen.dart';
import 'package:sapere/views/dashboard/creations/creation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:sapere/views/dashboard/stream/stream.dart';
import 'package:sapere/views/dashboard/history/history_screen.dart';
import '../../core/services/app_rating_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/services/local_storage_service.dart';
import '../../providers/sapere_provider.dart';
import '../../routes/app_pages.dart';
import 'widgets/bottom_sheet_content.dart';
import '../../widgets/mini_player.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  FileImage? image;

  @override
  build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return ChangeNotifierProvider(
      create: (BuildContext context) => DashboardVm(context),
      child: Consumer<InAppPurchaseProvider>(
        builder: (context, provider, child) {
          return Consumer<DashboardVm>(
            builder: (context, vm, child) {
              return Scaffold(
                backgroundColor: AppColors.kDeepBlack,
                extendBody: true,
                body: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 60.h),
                      child: vm.pages[vm.currentIndex],
                    ),
                    const MiniPlayer(),
                  ],
                ),
                floatingActionButton:
                    vm.currentIndex == 3
                        ? null
                        : Padding(
                          key: vm.fab,
                          padding: EdgeInsets.only(bottom: 25.h),
                          child: CustomShakeAnimation(
                            begin: '-3.0',
                            end: '3.0',
                            isLeaf: false,
                            child: InkWell(
                              onTap: () async {
                                try {
                                  final provider =
                                      Provider.of<InAppPurchaseProvider>(
                                        context,
                                        listen: false,
                                      );

                                  // 2026 Strategy: Paywall ONLY on creation
                                  if (!provider.isSubscribed) {
                                    Get.toNamed(Routes.freeTrialScreen);
                                    return;
                                  }

                                  await provider.check();
                                  final bukBukProvider =
                                      Provider.of<BukBukProvider>(
                                        context,
                                        listen: false,
                                      );
                                  bukBukProvider.isCommuinty = false;

                                  showModalBottomSheet(
                                    isScrollControlled: true,
                                    enableDrag: true,
                                    context: context,
                                    useSafeArea: true,
                                    // showDragHandle: true,
                                    builder: (BuildContext context) {
                                      return const BottomSheetContent();
                                    },
                                    backgroundColor: AppColors.whiteColor,
                                  );
                                } catch (e) {
                                  print('Error checking post limit: $e');
                                  Get.snackbar(
                                    'Error',
                                    'wentWrong'.tr,
                                    backgroundColor: Colors.red,
                                    colorText: AppColors.textColor,
                                  );
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    AppImagesUrls.addSymbol,
                                    height: 85.h,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                // floatingActionButton: ExpandableFab(),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: Container(
                  margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.kGlassBackground,
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: AppColors.kGlassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: BottomNavigationBar(
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedItemColor: AppColors.textColor,
                        unselectedItemColor: Colors.white38,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedLabelStyle: textTheme.bodySmall!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: textTheme.bodySmall!.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        currentIndex: vm.currentIndex,
                        onTap: (value) {
                          vm.setIndex(value);
                        },
                        type: BottomNavigationBarType.fixed,
                        items: [
                          BottomNavigationBarItem(
                            key: vm.home,
                            icon: Icon(
                              CupertinoIcons
                                  .headphones, // Or Icons.headset_rounded
                              size: 28.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            label: 'streaming'.tr,
                            activeIcon: CustomShakeAnimation(
                              begin: '-5.0',
                              end: '5.0',
                              isLeaf: false,
                              child: ShaderMask(
                                shaderCallback:
                                    (Rect bounds) => AppColors
                                        .premiumGoldGradient
                                        .createShader(bounds),
                                child: Icon(
                                  CupertinoIcons.headphones,
                                  size: 30.sp,
                                  color:
                                      Colors
                                          .white, // The gradient will mask this color
                                ),
                              ),
                            ),
                          ),
                          BottomNavigationBarItem(
                            key: vm.challenge,
                            icon: Icon(
                              CupertinoIcons.square_grid_2x2,
                              size: 26.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            label: 'categories'.tr,
                            activeIcon: CustomShakeAnimation(
                              begin: '-5.0',
                              end: '5.0',
                              isLeaf: false,
                              child: ShaderMask(
                                shaderCallback:
                                    (Rect bounds) => AppColors
                                        .premiumGoldGradient
                                        .createShader(bounds),
                                child: Icon(
                                  CupertinoIcons.square_grid_2x2,
                                  size: 28.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          BottomNavigationBarItem(
                            key: vm.books,
                            icon: Icon(
                              CupertinoIcons.plus_circle,
                              size: 28.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            label: 'creates'.tr,
                            activeIcon: CustomShakeAnimation(
                              begin: '-5.0',
                              end: '5.0',
                              isLeaf: false,
                              child: ShaderMask(
                                shaderCallback:
                                    (Rect bounds) => AppColors
                                        .premiumGoldGradient
                                        .createShader(bounds),
                                child: Icon(
                                  CupertinoIcons
                                      .plus_circle_fill, // Filled variant for active state
                                  size: 30.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          BottomNavigationBarItem(
                            key: vm.social,
                            icon: Icon(
                              Icons.history_rounded,
                              size: 28.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            label: 'history'.tr,
                            activeIcon: CustomShakeAnimation(
                              begin: '-5.0',
                              end: '5.0',
                              isLeaf: false,
                              child: ShaderMask(
                                shaderCallback:
                                    (Rect bounds) => AppColors
                                        .premiumGoldGradient
                                        .createShader(bounds),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 30.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DashboardVm extends ChangeNotifier {
  DashboardVm(BuildContext context) {
    init(context);
  }

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  late TutorialService tutorialService;

  int currentIndex = 0;
  List<Widget> pages = [
    const HomeScreen(),
    const CategoriesScreen(),
    const CreationScreen(),
    const HistoryScreen(),
  ];

  setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  final GlobalKey home = GlobalKey();
  final GlobalKey challenge = GlobalKey();
  final GlobalKey fab = GlobalKey();
  final GlobalKey books = GlobalKey();
  final GlobalKey social = GlobalKey();

  Future<void> init(BuildContext context) async {
    final localStorage = LocalStorage();

    final hasSeenTutorial =
        await localStorage.getData(key: AppLocalKeys.tutorialDashboard) ??
        'false';

    if (hasSeenTutorial == 'false') {
      firebaseCustomEvent();

      tutorialService = TutorialService(
        context: context,
        targets: _createTargets(),
        tutorialKey: AppLocalKeys.tutorialDashboard,
      );

      await tutorialService.showIfNeeded();
      await localStorage.setData(
        key: AppLocalKeys.tutorialDashboard,
        value: 'true',
      );
    }

    // Re-enabled automated rating dialog as per user request (The "Evaluator")
    if (Platform.isAndroid || Platform.isIOS) {
      await AppRatingService.instance.init();
      if (context.mounted) {
        await AppRatingService.instance.maybeShowRatingDialog(context);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      provider.fetchUserData();
    });
  }

  firebaseCustomEvent() async {
    log('analytics event triggers');
    await analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen': 'main_screen'},
    );
  }

  Future<void> checkAndShowFreeTrial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenFreeTrialScreen') ?? false;

    if (!seen) {
      await Get.toNamed(Routes.freeTrialScreen);

      await prefs.setBool('seenFreeTrialScreen', true);
    }
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        keyTarget: home,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "streamingLibrary".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "allFreeAudiobooks".tr,
                    style: TextStyle(color: AppColors.whiteColor, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        keyTarget: challenge,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "exploreCategory".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "findAudiobooks".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        keyTarget: fab,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "createCustomBook".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "describeYourStory".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        keyTarget: books,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "myCreations".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "myCreationsSection".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        keyTarget: social,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "community".tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "communitySection".tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }
}
