import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/widgets/primary_password_textfelid.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/widgets/primary_button.dart';

import 'dart:ui' as ui;

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => SignInScreenVM(),
      child: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          return Consumer<SignInScreenVM>(
            builder: (context, vm, child) {
              return Scaffold(
                backgroundColor: AppColors.kDeepBlack,
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
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
                    // Subtle overlay pattern
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
                    SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Form(
                          key: vm.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 100.h),
                              // Centered App Logo
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Image.asset(
                                  AppImagesUrls.logo,
                                  height: 120.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 40.h),
                              // Welcome Text
                              Text(
                                'signInTitle'.tr,
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textColor,
                                  fontFamily: 'NotoSerifDisplay',
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'signInSubTitle'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: AppColors.whiteColor.withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 40.h),
                              // Glassmorphism Form Container
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(24.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        PrimaryTextFormField(
                                          hintText: 'usernameEmail'.tr,
                                          controller: vm.userEmailC,
                                          labelText: 'usernameEmail'.tr,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          hintTextColor: AppColors.whiteColor
                                              .withOpacity(0.4),
                                          validator: (e) {
                                            if (e!.isEmpty) {
                                              return 'validatorName'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 20.h),
                                        PasswordTextField(
                                          labelText: 'password'.tr,
                                          hintText: 'password'.tr,
                                          controller: vm.passController,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'validatorPassword'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 12.h),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                Routes.forgotPasswordScreen,
                                              );
                                            },
                                            child: Text(
                                              'forgetText'.tr,
                                              style: TextStyle(
                                                color: AppColors.textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20.h),
                                        // Login Button with Gold Gradient
                                        provider.isLoading
                                            ? Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.textColor,
                                              ),
                                            )
                                            : PrimaryButton(
                                              onTap: () async {
                                                if (vm.formKey.currentState!
                                                    .validate()) {
                                                  await provider.signIn(
                                                    email:
                                                        vm.userEmailC.text
                                                            .trim(),
                                                    password:
                                                        vm.passController.text
                                                            .trim(),
                                                    context: context,
                                                  );
                                                }
                                              },
                                              text: 'signIn'.tr,
                                              textColor: Colors.black,
                                              bgColor: AppColors.primaryColor,
                                              gradient: AppColors.kGoldGradient,
                                              borderRadius: 16.r,
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30.h),
                              Text(
                                'or'.tr,
                                style: TextStyle(
                                  color: AppColors.whiteColor.withOpacity(0.5),
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              // Social Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: AppImagesUrls.googleIcon,
                                      label: 'Google',
                                      isPrimary: true,
                                      isLoading: provider.isGoogleLoading,
                                      onTap:
                                          () => provider.signInWithGoogle(
                                            context,
                                          ),
                                    ),
                                  ),
                                  if (Platform.isIOS) ...[
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: _buildSocialButton(
                                        icon: AppImagesUrls.appleIcon,
                                        label: 'Apple',
                                        isLoading: provider.isAppleLoading,
                                        onTap:
                                            () => provider.signInWithApple(
                                              context,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 30.h),
                              // Sign Up Link
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: "authBottomText".tr,
                                    style: TextStyle(
                                      color: AppColors.whiteColor.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14.sp,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'signUp'.tr,
                                        style: TextStyle(
                                          color: AppColors.textColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.pushNamed(
                                                  context,
                                                  Routes.signUpScreen,
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40.h),
                            ],
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
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? Colors.white : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow:
              isPrimary
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child:
            isLoading
                ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isPrimary ? Colors.black : Colors.white,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(icon, width: 22.w),
                    SizedBox(width: 12.w),
                    Text(
                      label,
                      style: TextStyle(
                        color: isPrimary ? Colors.black : Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class SignInScreenVM extends ChangeNotifier {
  SignInScreenVM() {
    // userEmailC.text = 'naseer.flutterdev@gmail.com';
    // passController.text = '123123';
  }

  final TextEditingController userEmailC = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void disposeControllers() {
    userEmailC.dispose();
    passController.dispose();
  }
}
