import 'dart:ui';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class GenerateArticlePage extends StatefulWidget {
  const GenerateArticlePage({super.key});

  @override
  State<GenerateArticlePage> createState() => _GenerateArticlePageState();
}

class _GenerateArticlePageState extends State<GenerateArticlePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Consumer<BukBukProvider>(
      builder: (context, provider, child) {
        if (provider.communityRequestStatus == CheckStatus.completed) {
          if (provider.isCommuinty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('Community post created, go to Quill page');
              Navigator.pushReplacementNamed(context, Routes.quillPage);
            });
          }
        } else {
          if (provider.rxRequestStatus == CheckStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('RX request completed, go to Dashboard');
              Navigator.pushReplacementNamed(context, Routes.dashboardScreen);
            });
          }
        }

        return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Stack(
            children: [
              // Cosmic / deep background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.kSamiOrange.withOpacity(0.15),
                        AppColors.blackColor,
                      ],
                      center: Alignment.center,
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
              // Floating ambient orbs (optional)
              Positioned(
                top: -100,
                left: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textColor.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textColor.withOpacity(0.1),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      if (provider.rxRequestStatus == CheckStatus.loading) ...[
                        const Spacer(flex: 2),
                        // Core "AI Engine" Animation
                        Center(
                          child: AvatarGlow(
                            glowColor: AppColors.kSamiOrange,
                            duration: const Duration(milliseconds: 2000),
                            repeat: true,
                            glowRadiusFactor: 0.8,
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 120.w,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.kSamiOrange.withOpacity(0.8),
                                      AppColors.textColor.withOpacity(0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.kSamiOrange.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 50.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50.h),
                        // Current Step Action (Dynamic Text)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          height: 80.h,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.3),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                provider.generationSteps.isNotEmpty
                                    ? provider.generationSteps.last
                                    : 'generatingText'.tr,
                                key: ValueKey<String>(
                                  provider.generationSteps.isNotEmpty
                                      ? provider.generationSteps.last
                                      : 'generating',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSerifDisplay',
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.kSamiOrange.withOpacity(
                                        0.8,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Previous Logs fading up (Terminal Style)
                        Expanded(
                          flex: 3,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                  Colors.black,
                                ],
                                stops: const [0.0, 0.4, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ListView.builder(
                              itemCount:
                                  provider.generationSteps.length > 1
                                      ? provider.generationSteps.length - 1
                                      : 0,
                              reverse:
                                  true, // Newest completed steps at the bottom
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(bottom: 20.h),
                              itemBuilder: (_, index) {
                                // Since we reverse, index 0 is the second to last element
                                int actualIndex =
                                    provider.generationSteps.length - 2 - index;
                                String step =
                                    provider.generationSteps[actualIndex];

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6.h,
                                    horizontal: 40.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.greenAccent.withOpacity(
                                          0.6,
                                        ),
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          step,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            fontSize: 14.sp,
                                            // Optional: make it look slightly monospace/terminal-like
                                            letterSpacing: 0.5,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      if (provider.rxRequestStatus == CheckStatus.error) ...[
                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 80.sp,
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                'wentWrong'.tr,
                                style: textTheme.headlineLarge!.copyWith(
                                  color: Colors.white70,
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
