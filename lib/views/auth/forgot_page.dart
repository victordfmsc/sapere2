import 'package:sapere/animation/auto_shake_animation.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:provider/provider.dart';

class ForGetPasswordPage extends StatefulWidget {
  const ForGetPasswordPage({super.key});

  @override
  State<ForGetPasswordPage> createState() => _ForGetPasswordPageState();
}

class _ForGetPasswordPageState extends State<ForGetPasswordPage> {
  final TextEditingController emailC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.whiteColor),
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
                            'forgotPasswordText'.tr,
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
                              fontSize: 32.sp,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'forgetSubTitle'.tr,
                      style: textTheme.displayMedium!.copyWith(
                        color: AppColors.textColor,
                        fontSize: 18.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    PrimaryTextFormField(
                      hintText: 'email'.tr,
                      keyboardType: TextInputType.emailAddress,
                      controller: emailC,
                      labelText: 'email'.tr,
                      hintTextColor: AppColors.hintTextColor,
                      validator: (e) {
                        if (e!.isEmpty) {
                          return 'validatorEmail'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 400.h),
                    provider.isLoadingEmail
                        ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.whiteColor,
                          ),
                        )
                        : PrimaryButton(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              provider.sendResetLink(
                                email: emailC.text,
                                context: context,
                              );
                            }
                          },
                          width: 382.w,
                          text: 'continueText'.tr,
                          textColor: AppColors.textColor,
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
