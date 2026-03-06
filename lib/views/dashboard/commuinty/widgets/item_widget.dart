import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/models/public_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sapere/widgets/sapere_image.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MyItem extends StatelessWidget {
  final PublicPost post;
  final bool isLike;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCommentTap;
  final VoidCallback onLikeTap;
  final VoidCallback onBookMarkTap;

  const MyItem({
    super.key,
    required this.post,
    required this.onCommentTap,
    required this.onLikeTap,
    required this.onBookMarkTap,
    required this.onTap,
    required this.onDelete,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 50.h,
                    width: 50.w,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: post.creator!.imageUrl.toString(),
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircularProgressIndicator(),
                        errorWidget:
                            (context, url, error) =>
                                Icon(Icons.person, color: AppColors.textColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.h),
                  SizedBox(
                    width: Get.width * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.creator!.name.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE dd MMMM yyyy HH:mm',
                          ).format(DateTime.parse(post.publishTime.toString())),
                          style: TextStyle(color: AppColors.textColor),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (post.creator?.uid ==
                      FirebaseAuth.instance.currentUser?.uid)
                    InkWell(
                      onTap: onDelete,
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                  SizedBox(width: 5.w),
                  InkWell(
                    onTap: onTap,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
              Text(
                post.dairyName.toString(),
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                post.description.toString(),
                maxLines: 4,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16.sp,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 15.h),
            ],
          ),
        ),
        post.newCover == null || post.newCover!.isEmpty
            ? const SizedBox()
            : Container(
              height: Get.height * 0.4,
              width: MediaQuery.of(context).size.width,
              color: AppColors.primaryColor.withOpacity(0.7),
              child: SapereImage(imageUrl: post.newCover!, fit: BoxFit.cover),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'likes'.tr} : ${post.totalLikes}',
                    style: TextStyle(color: AppColors.textColor),
                  ),
                  Text(
                    '${'comments'.tr} : ${post.totalComments}',
                    style: TextStyle(color: AppColors.textColor),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Divider(color: AppColors.textColor),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onLikeTap,
                    child: Row(
                      children: [
                        isLike
                            ? const Icon(Icons.favorite, color: Colors.red)
                            : Icon(
                              Icons.favorite_border,
                              color: AppColors.textColor,
                            ),
                        SizedBox(width: 5.w),
                        Text(
                          'like'.tr,
                          style: TextStyle(color: AppColors.textColor),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onCommentTap,
                    child: Row(
                      children: [
                        Icon(
                          Icons.mode_comment,
                          color: AppColors.textColor,
                          size: 30,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'comments'.tr,
                          style: TextStyle(color: AppColors.textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ],
    );
  }
}
