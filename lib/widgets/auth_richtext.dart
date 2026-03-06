import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../core/constant/colors.dart';

class AuthRich extends StatefulWidget {
  final void Function() onTap;
  const AuthRich({super.key, required this.onTap});

  @override
  State<AuthRich> createState() => _AuthRichState();
}

class _AuthRichState extends State<AuthRich> {
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'authBottomText'.tr,
          style: textTheme.bodyMedium!.copyWith(
            color: AppColors.lightBlackColor,
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: widget.onTap,
          child: Text(
            'signUp'.tr,
            style: textTheme.bodyMedium!.copyWith(
              color: AppColors.primaryColor,
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
