import 'package:sapere/animation/auto_shake_animation.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordC = TextEditingController();
  final TextEditingController newPasswordC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Flexible(
                          fit: FlexFit.tight,
                          child: Text(
                            'changePasswordTitle'.tr,
                            style: textTheme.displayMedium!.copyWith(
                              color: AppColors.textColor,
                              fontSize: 32.sp,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CustomShakeAnimation(
                          begin: '-5.0',
                          isLeaf: false,
                          end: '5.0',
                          child: Text(
                            forgetEmoji,
                            style: textTheme.displayMedium!.copyWith(
                              color: AppColors.textColor,
                              fontSize: 32.sp,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'changeSubTitleText'.tr,
                      style: textTheme.displayMedium!.copyWith(
                        color: AppColors.textColor,
                        fontSize: 18.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 32.h),

                    PrimaryTextFormField(
                      hintText: 'currentPassword'.tr,
                      labelText: 'currentPassword'.tr,
                      controller: currentPasswordC,
                      hintTextColor: AppColors.hintTextColor,
                      keyboardType: TextInputType.visiblePassword,
                      isSuffixIcon: true,
                      suffixIconWidget: Icon(Icons.lock_outline,
                          size: 20.sp, color: AppColors.whiteColor),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'validatorCurrentPassword'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    // New Password Field
                    PrimaryTextFormField(
                      hintText: 'newPassword'.tr,
                      labelText: 'newPassword'.tr,
                      controller: newPasswordC,
                      hintTextColor: AppColors.hintTextColor,
                      keyboardType: TextInputType.visiblePassword,
                      isSuffixIcon: true,
                      suffixIconWidget: Icon(Icons.lock_reset,
                          size: 20.sp, color: AppColors.whiteColor),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'validatorNewPassword'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 80.h),

                    provider.isChangeLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : PrimaryButton(
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                provider.changePassword(
                                  currentPassword: currentPasswordC.text.trim(),
                                  newPassword: newPasswordC.text.trim(),
                                  context: context,
                                );
                              }
                            },
                            width: 382.w,
                            text: 'continueText'.tr,
                            textColor: AppColors.whiteColor,
                            bgColor: AppColors.primaryColor,
                            borderRadius: 100,
                            fontSize: 14,
                            height: 62.h,
                            elevation: 0,
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
