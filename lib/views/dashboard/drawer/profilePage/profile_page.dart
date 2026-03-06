// ignore_for_file: unnecessary_null_comparison

import 'package:sapere/animation/scaletransition_animation.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:sapere/views/dashboard/drawer/profilePage/widgets/profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Widget> profileOptions = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isEmail = userProvider.user?.signIn == 'email';
    final appTextStyle = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.whiteColor),
        title: Text(
          'profile'.tr,
          style: appTextStyle.displayMedium!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.blackColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Center(
              child: ScalesTransitionAnimation(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: AppColors.kLinearGradient,
                        ),
                      ),
                      child: userProvider.user?.profileImage == 'null'
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  const AssetImage(AppImagesUrls.avterHolder),
                              backgroundColor: AppColors.greyColor,
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(
                                userProvider.user?.profileImage ?? '',
                              ),
                              backgroundColor: AppColors.greyColor,
                            ),
                    ),
                    SizedBox(height: 15.h),
                    Text.rich(
                      TextSpan(
                        style: appTextStyle.displayMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                          color: AppColors.textColor,
                        ),
                        children: [
                          TextSpan(
                            text: userProvider.user?.userName == 'null'
                                ? 'name'
                                : userProvider.user?.userName ?? '',
                          ),
                          TextSpan(
                            text: ' | ${userProvider.user?.userType ?? ''}',
                            style: appTextStyle.displayMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: AppColors.textColor,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 45.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  ProfileCards(
                    svgIcon: AppImagesUrls.kPerson,
                    title: 'reUsableListTitle1'.tr,
                    onTap: () {
                      Navigator.pushNamed(context, Routes.editProfileScreen);
                    },
                    isDrawer: false,
                  ),
                  SizedBox(height: 20.h),
                  if (isEmail) ...[
                    ProfileCards(
                      svgIcon: AppImagesUrls.kLock,
                      title: 'reUsableListTitle3'.tr,
                      onTap: () {
                        Navigator.pushNamed(context, Routes.changePasswordPage);
                      },
                      isDrawer: false,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
