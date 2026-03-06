import 'dart:io';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/services/image_picker.dart';
import 'package:sapere/models/user_model.dart';
import 'package:sapere/providers/user_provider.dart';
import 'package:sapere/widgets/primary_button.dart';
import 'package:sapere/widgets/primarytextfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    final uc = Provider.of<UserProvider>(context, listen: false);
    loadData(uc);
  }

  void loadData(UserProvider uc) {
    nameC.text = uc.user?.userName ?? '';
    phoneC.text = uc.user?.phone ?? '';
    dateC.text = uc.user?.dateOfBirth ?? '';
    genderC.text = uc.user?.gender ?? 'gender'.tr;
    urlImage = uc.user?.profileImage ?? '';
    addressC.text = uc.user?.address ?? '';
  }

  File? _pickedImage;
  String _selectedGender = 'gender'.tr;
  DateTime selectedDate = DateTime.now();
  TextEditingController nameC = TextEditingController();
  TextEditingController phoneC = TextEditingController();
  TextEditingController dateC = TextEditingController();
  TextEditingController addressC = TextEditingController();
  TextEditingController genderC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? urlImage;
  final service = ImagePickerService();
  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        final image = _pickedImage ?? provider.pickedImage;
        final profileUrl = urlImage ?? provider.user?.profileImage ?? '';
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppColors.whiteColor),
            title: Text(
              'editProfile'.tr,
              style: appTextStyle.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: AppColors.textColor),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  Stack(
                    children: [
                      image != null
                          ? CircleAvatar(
                              radius: 60.r, backgroundImage: FileImage(image))
                          : profileUrl == 'null' || profileUrl.isEmpty
                              ? CircleAvatar(
                                  radius: 60.r,
                                  backgroundImage: const AssetImage(
                                      AppImagesUrls.ellipseLogo))
                              : CircleAvatar(
                                  radius: 60.r,
                                  backgroundImage: NetworkImage(profileUrl)),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await service.imagePick(
                                source: ImageSource.gallery);
                            if (picked != null) {
                              provider.setPickedImage(picked);
                              setState(() {
                                _pickedImage = picked;
                                urlImage = '';
                              });
                            }
                          },
                          child: SvgPicture.asset(
                            AppImagesUrls.editSquare,
                            width: 40.w,
                            height: 40.h,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  PrimaryTextFormField(
                    hintText: 'fullName'.tr,
                    controller: nameC,
                    labelText: 'fullName'.tr,
                    hintTextColor: AppColors.textColor,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'validatorName'.tr;
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  PrimaryTextFormField(
                    hintText: '+1 000 000 000',
                    controller: phoneC,
                    labelText: 'phoneNumber'.tr,
                    keyboardType: TextInputType.phone,
                    hintTextColor: AppColors.textColor,
                    validator: (e) {
                      if (e!.isEmpty) {
                        return 'validatorPhone'.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  PrimaryTextFormField(
                    hintText: 'gender'.tr,
                    labelText: 'gender'.tr,
                    controller: genderC,
                    onChanged: (value) {
                      _selectedGender = value;
                    },
                    hintTextColor: AppColors.textColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your gender';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  PrimaryTextFormField(
                    hintText: 'hintDateBirth'.tr,
                    controller: dateC,
                    labelText: 'hintDateBirth'.tr,
                    hintTextColor: AppColors.textColor,
                    suffixIconWidget: Padding(
                      padding: const EdgeInsets.all(8.0).copyWith(right: 0),
                      child: SvgPicture.asset(
                        AppImagesUrls.Calendar,
                        width: 23.w,
                        height: 23.h,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    isSuffixIcon: true,
                    onTab: () => _showDialog(
                      CupertinoDatePicker(
                        initialDateTime: selectedDate,
                        mode: CupertinoDatePickerMode.date,
                        use24hFormat: true,
                        showDayOfWeek: true,
                        onDateTimeChanged: (DateTime newDate) {
                          setState(() {
                            selectedDate = newDate;
                            dateC.text =
                                newDate.toLocal().toString().split(' ')[0];
                          });
                        },
                      ),
                    ),
                    validator: (e) {
                      if (e!.isEmpty) {
                        return 'validatorDateBirth'.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),
                  PrimaryTextFormField(
                    hintText: 'address'.tr,
                    controller: addressC,
                    labelText: 'address'.tr,
                    hintTextColor: AppColors.hintTextColor,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'validatorAddress'.tr;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 44.h),
                  provider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : PrimaryButton(
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              final userModel = UserModel(
                                uId: provider.user!.uId,
                                userName: nameC.text,
                                email: provider.user!.email,
                                profileImage: provider.user!.profileImage,
                                gender: _selectedGender,
                                phone: phoneC.text,
                                dateOfBirth: dateC.text,
                                address: addressC.text,
                                credits: provider.user!.credits,
                                signIn: provider.user!.signIn,
                                userType: provider.user!.userType,
                              );

                              await provider.updateUser(
                                  userModel: userModel,
                                  pickedImage: provider.pickedImage,
                                  context: context);
                            }
                          },
                          width: 382.w,
                          text: 'saveText'.tr,
                          textColor: AppColors.whiteColor,
                          bgColor: AppColors.primaryColor,
                          borderRadius: 100,
                          fontSize: 14,
                          height: 62.h,
                          elevation: 0,
                        ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }
}
