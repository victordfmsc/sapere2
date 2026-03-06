import 'package:avatar_glow/avatar_glow.dart' show AvatarGlow;
import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sapere/widgets/sapere_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CircularCoverWithWaveEffect extends StatelessWidget {
  final String cover;

  const CircularCoverWithWaveEffect({super.key, required this.cover});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Center(
          child: AvatarGlow(
            glowColor: AppColors.textColor.withOpacity(0.5),
            glowCount: 2,
            glowRadiusFactor: 0.15,
            animate: true,
            repeat: true,
            child: Container(
              height: 220.w,
              width: 220.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: SapereImage(imageUrl: cover, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}
