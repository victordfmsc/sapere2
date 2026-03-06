import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SecondaryButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text, icons;
  final double? width;
  final double? height;
  final double borderRadius;
  final double? fontSize;
  final Color textColor, bgColor;
  final Color? iconColor;

  const SecondaryButton(
      {super.key,
      this.iconColor,
      required this.onTap,
      required this.text,
      this.width,
      this.height,
      required this.icons,
      this.borderRadius = 20,
      this.fontSize,
      required this.textColor,
      required this.bgColor});

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 90.w).copyWith(right: 55.w),
        height: widget.height ?? 55.h,
        alignment: Alignment.center,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: widget.bgColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: AppColors.primaryColor,
                blurRadius: 2,
                spreadRadius: 0.01),
          ],
          // border: Border.all(
          //   color: AppColors.primaryColor,
          // ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              widget.icons,
              width: 26.w,
              height: 26.w,
            ),
            SizedBox(width: 12.w),
            Text(widget.text,
                style: appTextStyle.bodyLarge!.copyWith(
                  color: widget.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                )),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }
}
