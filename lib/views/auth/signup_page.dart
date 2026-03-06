import 'dart:io';
import 'dart:ui' as ui;

import 'package:sapere/animation/auto_shake_animation.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/image_picker.dart';
import 'package:sapere/models/user_model.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/widgets/primary_password_textfelid.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'components/PolicyCheckbox.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider(
      create: (BuildContext context) => SignUpVM(),
      child: Consumer<SignUpVM>(
        builder: (context, vm, child) {
          return Consumer<AuthProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                backgroundColor: AppColors.blackColor,
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
                              // Header
                              _buildTopHeader(textTheme),
                              SizedBox(height: 30.h),
                              _buildImagePicker(context, vm),
                              SizedBox(height: 30.h),
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
                                          hintText: 'fullName'.tr,
                                          controller: vm.nameC,
                                          hintTextColor: AppColors.whiteColor
                                              .withOpacity(0.4),
                                          labelText: 'fullName'.tr,
                                          validator:
                                              (e) =>
                                                  e!.isEmpty
                                                      ? 'validatorName'.tr
                                                      : null,
                                        ),
                                        SizedBox(height: 20.h),
                                        PrimaryTextFormField(
                                          controller: vm.emailController,
                                          labelText: 'email'.tr,
                                          hintText: 'hintEmail'.tr,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          hintTextColor: AppColors.whiteColor
                                              .withOpacity(0.4),
                                          validator: (value) {
                                            if (value!.isEmpty ||
                                                !value.contains('@') ||
                                                !value.contains('.')) {
                                              return 'validatorEmail'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 20.h),
                                        PrimaryTextFormField(
                                          hintText: '+1 000 000 000',
                                          controller: vm.phoneC,
                                          labelText: 'phoneNumber'.tr,
                                          keyboardType: TextInputType.phone,
                                          hintTextColor: AppColors.whiteColor
                                              .withOpacity(0.4),
                                        ),
                                        SizedBox(height: 20.h),
                                        _buildGenderDropdown(vm),
                                        SizedBox(height: 20.h),
                                        PrimaryTextFormField(
                                          controller: vm.dateC,
                                          labelText: 'labelDateBirth'.tr,
                                          hintText: 'hintDateBirth'.tr,
                                          hintTextColor: AppColors.whiteColor
                                              .withOpacity(0.4),
                                          isSuffixIcon: true,
                                          suffixIconWidget: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SvgPicture.asset(
                                              AppImagesUrls.Calendar,
                                              width: 23.w,
                                              height: 23.h,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          onTab:
                                              () => _showDialog(
                                                context,
                                                CupertinoDatePicker(
                                                  initialDateTime:
                                                      vm.selectedDate,
                                                  mode:
                                                      CupertinoDatePickerMode
                                                          .date,
                                                  showDayOfWeek: true,
                                                  onDateTimeChanged: vm.setDate,
                                                ),
                                              ),
                                        ),
                                        SizedBox(height: 20.h),
                                        PasswordTextField(
                                          labelText: 'password'.tr,
                                          hintText: 'password'.tr,
                                          controller: vm.passwordC,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'validatorNewPassword'.tr;
                                            }
                                            if (value.length < 6) {
                                              return 'validatorCharacters'.tr;
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 12.h),
                                        const PolicyCheckbox(),
                                        SizedBox(height: 30.h),
                                        provider.isLoading
                                            ? Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryColor,
                                              ),
                                            )
                                            : InkWell(
                                              onTap: () {
                                                if (vm.formKey.currentState!
                                                    .validate()) {
                                                  if (vm.pickedImage == null) {
                                                    Get.snackbar(
                                                      'warningImage'.tr,
                                                      'warning'.tr,
                                                      colorText:
                                                          AppColors.textColor,
                                                    );
                                                  } else if (provider
                                                      .isChecked) {
                                                    UserModel
                                                    userModel = UserModel(
                                                      uId: '',
                                                      userName:
                                                          vm.nameC.text.trim(),
                                                      email:
                                                          vm
                                                              .emailController
                                                              .text
                                                              .trim(),
                                                      profileImage: '',
                                                      gender:
                                                          vm.selectedGender
                                                              .toString(),
                                                      dateOfBirth:
                                                          vm.dateC.text.trim(),
                                                      phone:
                                                          vm.phoneC.text.trim(),
                                                      address: '',
                                                      credits: 0,
                                                      signIn: 'email',
                                                      userType: 'normal',
                                                    );

                                                    provider.signUp(
                                                      password:
                                                          vm.passwordC.text,
                                                      file: vm.pickedImage!,
                                                      email:
                                                          vm
                                                              .emailController
                                                              .text,
                                                      userModel: userModel,
                                                      context: context,
                                                    );
                                                  } else {
                                                    Get.snackbar(
                                                      'warningImage'.tr,
                                                      'acceptPrivacyPolicy'.tr,
                                                      colorText:
                                                          AppColors.textColor,
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                height: 56.h,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xffD4AF37),
                                                          Color(0xffB8860B),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xffD4AF37,
                                                      ).withOpacity(0.3),
                                                      blurRadius: 15,
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'continueText'.tr,
                                                    style: TextStyle(
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
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
                              // Social Buttons (Re-using buildSocialButton pattern if needed, or dedicated ones)
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

  Widget _buildTopHeader(TextTheme textTheme) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'profileText'.tr,
            style: textTheme.displayMedium!.copyWith(
              color: AppColors.textColor,
              fontSize: 32.sp,
              height: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        CustomShakeAnimation(
          begin: '-5.0',
          end: '5.0',
          isLeaf: false,
          child: Text(
            profileEmoji,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 25.sp,
              height: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context, SignUpVM provider) {
    return Stack(
      children: [
        Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image:
                  provider.pickedImage == null
                      ? const AssetImage(AppImagesUrls.ellipseLogo)
                      : FileImage(provider.pickedImage!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () async {
              final image = await ImagePickerService().imagePick(
                source: ImageSource.gallery,
              );
              provider.setImage(image);
            },
            child: SvgPicture.asset(
              AppImagesUrls.editSquare,
              width: 40.w,
              height: 40.h,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(SignUpVM provider) {
    return Container(
      padding: EdgeInsets.only(left: 14.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primaryColor)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedGender,
          dropdownColor: AppColors.blackColor.withBlue(22),
          isExpanded: true,
          iconDisabledColor: AppColors.textColor,
          iconEnabledColor: AppColors.textColor,
          onChanged: provider.setGender,
          items:
              ['gender'.tr, 'male'.tr, 'female'.tr, 'other'.tr].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: AppColors.textColor),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(top: false, child: child),
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

class SignUpVM extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final service = ImagePickerService();
  File? pickedImage;
  String selectedGender = 'Male';
  bool isLoading = false;
  bool isChecked = false;
  DateTime selectedDate = DateTime.now();

  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final dateC = TextEditingController();
  final passwordC = TextEditingController();
  final emailController = TextEditingController();

  void setImage(File? file) {
    pickedImage = file;
    notifyListeners();
  }

  void setGender(String? gender) {
    if (gender != null) {
      selectedGender = gender;
      notifyListeners();
    }
  }

  void toggleLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void toggleCheck(bool value) {
    isChecked = value;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    dateC.text = date.toLocal().toString().split(' ')[0];
    notifyListeners();
  }

  void disposeControllers() {
    nameC.dispose();
    phoneC.dispose();
    dateC.dispose();
    passwordC.dispose();
    emailController.dispose();
  }
}
