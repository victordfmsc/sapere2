import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/auth_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PolicyCheckbox extends StatefulWidget {
  const PolicyCheckbox({super.key});

  @override
  _PolicyCheckboxState createState() => _PolicyCheckboxState();
}

class _PolicyCheckboxState extends State<PolicyCheckbox>
    with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  final Duration _animationDuration = const Duration(milliseconds: 500);
  final Tween<double> _tween = Tween<double>(begin: 0.95, end: 1.0);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryColor,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r),
            ),
            title: AnimatedDefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: auth.isChecked
                        ? AppColors.textColor
                        : AppColors.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
              duration: const Duration(milliseconds: 500),
              child: ScaleTransition(
                scale: _tween.animate(
                  CurvedAnimation(
                    parent: animationController!,
                    curve: Curves.easeOut,
                    reverseCurve: Curves.easeIn,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.termsConditionPage);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'iAccept'.tr,
                      style: TextStyle(
                          color: auth.isChecked
                              ? AppColors.textColor
                              : AppColors.textColor,
                          fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'privacyPolicyText'.tr,
                          style: TextStyle(
                            color: auth.isChecked
                                ? AppColors.textColor
                                : AppColors.textColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            value: auth.isChecked,
            onChanged: (value) {
              auth.toggleCheck(value ?? false);
              animationController!.forward().then((_) {
                animationController!.reverse();
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            secondary: AnimatedBuilder(
              animation: animationController!,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: auth.isChecked ? 1.5 : 1.2,
                  child: Icon(Icons.check,
                      color: auth.isChecked
                          ? AppColors.whiteColor
                          : AppColors.textColor),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
