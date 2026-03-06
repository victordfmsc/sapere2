import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MySelectLanguage extends StatelessWidget {
  const MySelectLanguage({
    super.key,
    required this.image,
    required this.text,
    required this.color,
    required this.textColor,
  });
  final String image;
  final String text;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      // padding: EdgeInsets.all(5),
      // margin: EdgeInsets.all(3),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33.r),
        color: color,
      ),
      margin: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(width: 23.w),
          SizedBox(
              height: 35.h,
              width: 35.w,
              child: SvgPicture.asset(image, fit: BoxFit.contain)),
          SizedBox(width: 20.w),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(fontSize: 16.sp, color: textColor),
              textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
