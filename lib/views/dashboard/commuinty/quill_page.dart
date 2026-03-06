import 'dart:io';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/models/post.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class QuillPage extends StatefulWidget {
  const QuillPage({super.key});

  @override
  State<QuillPage> createState() => _QuillPageState();
}

class _QuillPageState extends State<QuillPage> {
  BukBukPost? post;
  // bool isEdit = false;
  FocusNode focusNode = FocusNode();
  File? dataFile;
  TextEditingController descriptionController = TextEditingController();
  TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLanguage();

    final provider = Provider.of<BukBukProvider>(context, listen: false);

    titleController.text = provider.sapereTitle;
    descriptionController.text = provider.descriptions!.join('\n\n');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkMe();
    });
  }

  String? codeLang;

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    setState(() {
      codeLang = storedLang ?? 'en_US';
    });
  }

  checkMe() async {
    FocusScope.of(context).requestFocus(focusNode);

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        descriptionController.selection = TextSelection.fromPosition(
          TextPosition(offset: descriptionController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BukBukProvider>(context, listen: false);

    TextTheme textTheme = Theme.of(context).textTheme;
    print('Book title: ${provider.sapereTitle}');
    print('Descriptions: ${provider.descriptions}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'addBukbuk'.tr,
          style: textTheme.labelLarge!.copyWith(
            fontSize: 18.sp,
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () async {
              provider.setIsUploading(true, message: "creatingPdf".tr);
              showDynamicLoadingDialog(context);

              try {
                dataFile = await provider.generatePdfForDescriptions(
                  provider.descriptions!,
                  titleController.text.trim(),
                  codeLang.toString(),
                );

                await provider.createCommunityPost(
                  pdfFile: dataFile!,
                  name: titleController.text,
                  context: context,
                  languageCode: codeLang.toString(),
                );

                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.dashboardScreen,
                  (route) => false,
                );

                Get.snackbar(
                  'bukBukCreated'.tr,
                  'bukBukCreatedAndUploaded'.tr,
                  colorText: AppColors.textColor,
                );
              } catch (e) {
                Navigator.of(context).pop();
                Get.snackbar(
                  'error'.tr,
                  '${'failedCreateBukBuk'.tr} ${e.toString()}',
                  colorText: AppColors.textColor,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                AppImagesUrls.saveSvg,
                color: AppColors.textColor,
                height: 30,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              onTapOutside: (e) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 20.sp,
                fontFamily: 'Charter',
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 2.h),
                hintText: 'title'.tr,
                border: InputBorder.none,
                alignLabelWithHint: true,
                hintStyle: TextStyle(
                  color: AppColors.textColor,
                  fontFamily: 'Charter',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Divider(color: AppColors.blackColor50, thickness: 2),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: TextField(
                  focusNode: focusNode,
                  controller: descriptionController,
                  onTap: () {},
                  onTapOutside: (e) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20.sp,
                    fontFamily: 'Charter',
                    height: 2.3.h,
                  ),
                  minLines: 15,
                  maxLines: 15,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 10.h, bottom: 34.h),
                    hintText: 'writeDairyHere'.tr,
                    border: InputBorder.none,
                    // counterStyle: TextStyle(color: theme.primaryColor),
                    // alignLabelWithHint: true,
                    hintStyle: TextStyle(
                      color: AppColors.textColor,
                      fontFamily: 'Charter',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}

void showDynamicLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Consumer<BukBukProvider>(
        builder: (_, provider, __) {
          return AlertDialog(
            backgroundColor: AppColors.blackColor50,
            content: Row(
              children: [
                CircularProgressIndicator(color: AppColors.textColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    provider.loadingMessage,
                    style: TextStyle(color: AppColors.textColor),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class ScrollableTextField extends StatefulWidget {
  const ScrollableTextField({
    super.key,
    required this.placeholder,
    required this.controller,
  });

  final String placeholder;
  final TextEditingController controller;

  @override
  State<ScrollableTextField> createState() => _ScrollableTextFieldState();
}

class _ScrollableTextFieldState extends State<ScrollableTextField> {
  final ScrollController _scrollController = ScrollController();

  double _thumbHeight = 0;
  double _thumbTop = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateThumbPosition);
  }

  void _updateThumbPosition() {
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.position.pixels;
    double viewportHeight = _scrollController.position.viewportDimension;
    setState(() {
      if (maxScroll != 0) {
        _thumbTop =
            (currentScroll / maxScroll) * (viewportHeight - _thumbHeight);
        _thumbHeight =
            viewportHeight * viewportHeight / (maxScroll + viewportHeight);
      } else {
        _thumbTop = 0;
        _thumbHeight = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            SingleChildScrollView(
              controller: _scrollController,
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),

            Positioned(
              top: 0,
              right: 0,
              child:
                  _thumbHeight == 0
                      ? Container()
                      : Container(
                        width: 10,
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
            ),

            // Thumb
            Positioned(
              top: _thumbTop,
              right: 0,
              child: Container(
                width: 10,
                height: _thumbHeight,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
