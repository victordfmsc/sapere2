import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:get/get.dart';
import 'package:sapere/widgets/sapere_image.dart';

class SapereCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onTap;
  final double? width;
  final bool isGenerating;
  final bool isFailed;
  final VoidCallback? onRetry;

  const SapereCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.onTap,
    this.width,
    this.isGenerating = false,
    this.isFailed = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 160.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3, // Poster aspect ratio
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SapereImage(imageUrl: imageUrl, fit: BoxFit.cover),
                    // Bottom shadow for text readability if needed
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (isFailed)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 28.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "generationFailed".tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              TextButton(
                                onPressed: onRetry,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  minimumSize: Size(0, 28.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                child: Text(
                                  "retryGeneration".tr,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (isGenerating)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "generatingText".tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
