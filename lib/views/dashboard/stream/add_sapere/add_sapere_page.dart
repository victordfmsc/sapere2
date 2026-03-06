// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/images.dart';
import 'package:sapere/core/constant/strings.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/providers/sapere_provider.dart';
// import 'package:sapere/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'custom_gallery.dart';
import 'package:sapere/widgets/voice_selector_widget.dart';
import 'package:sapere/core/constant/voice_data.dart';
import 'package:sapere/widgets/dailogs/creation_motivator_dialog.dart';

class AddSaperePage extends StatefulWidget {
  const AddSaperePage({super.key});

  @override
  State<AddSaperePage> createState() => _AddSaperePageState();
}

class _AddSaperePageState extends State<AddSaperePage> {
  TextEditingController descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String _partialText = "";
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isPaused = false;
  bool isKeyboardVisible = false;
  String? codeLang;
  bool _isProcessing = false;

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    setState(() {
      codeLang = storedLang ?? 'en_US';
    });
  }

  @override
  void initState() {
    super.initState();
    listenForPermissions();
    _loadLanguage();
  }

  final ScrollController _scrollController = ScrollController();
  FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void listenForPermissions() async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
        break;
      case PermissionStatus.limited:
        break;
      case PermissionStatus.permanentlyDenied:
        break;
      case PermissionStatus.restricted:
        break;
      case PermissionStatus.provisional:
    }
  }

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }

  _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Consumer<BukBukProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.blackColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textColor,
                elevation: 0,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 10.h),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 8.h,
                          ),
                          child: Text(
                            "What do you want to learn today?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.kSamiOrange.withOpacity(0.08),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.kSamiOrange.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            focusNode: focusNode,
                            scrollController: _scrollController,
                            style: TextStyle(color: AppColors.textColor),
                            onTapOutside: (e) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            controller: descriptionController,
                            maxLines:
                                isKeyboardVisible
                                    ? 11
                                    : 14, // reduced slightly to fit title
                            decoration: InputDecoration(
                              hintText: 'descriptionHintText'.tr,
                              hintStyle: TextStyle(
                                color: Colors.white30,
                                height: 1.5,
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.all(16.w),
                            ),
                          ),
                        ),
                        // Divider(color: AppColors.primaryColor),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    if (_speechEnabled && _partialText.isNotEmpty)
                      SizedBox(
                        width: Get.width,
                        height: Get.height * 0.1,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Text(
                              _partialText,
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottomSheet:
                  isKeyboardVisible
                      ? const SizedBox()
                      : Container(
                        height: Get.height * 0.25,
                        width: Get.width,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          border: Border.all(color: Colors.grey.shade900),
                          color: AppColors.blackColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _speechEnabled
                                ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _speechEnabled = false;
                                      _isPaused = true;
                                      _speechToText.stop();
                                      _scrollToEnd();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.pause_circle_filled,
                                    size: 70,
                                    color: AppColors.textColor,
                                  ),
                                )
                                : InkWell(
                                  onTap: () async {
                                    showModalBottomSheet(
                                      isScrollControlled: true,
                                      enableDrag: true,
                                      context: context,
                                      showDragHandle: true,
                                      useSafeArea: true,
                                      backgroundColor: AppColors.whiteColor,
                                      builder: (BuildContext context) {
                                        return CustomGallery(
                                          onImageSelected: (selectedPath) {
                                            provider.setSelectedCover(
                                              selectedPath,
                                            );

                                            print(selectedPath);
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        child:
                                            provider.selectedCover.isNotEmpty
                                                ? Image.network(
                                                  provider.selectedCover,
                                                  height: 80.h,
                                                  width: 80.h,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  height: 80.h,
                                                  width: 80.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.05),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.auto_awesome,
                                                        color:
                                                            AppColors.textColor,
                                                        size: 24.sp,
                                                      ),
                                                      SizedBox(height: 4.h),
                                                      Text(
                                                        "autoCover".tr,
                                                        style: TextStyle(
                                                          color:
                                                              AppColors
                                                                  .textColor,
                                                          fontSize: 8.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                      ),
                                      if (provider.selectedCover.isEmpty)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            decoration: BoxDecoration(
                                              color: AppColors.textColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 12.sp,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            // ── Voice Selector Button ──
                            GestureDetector(
                              onTap: () {
                                if (codeLang == null) return;
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (_) => VoiceSelectorWidget(
                                        localeCode: codeLang!,
                                        currentVoiceId:
                                            provider.selectedVoiceId,
                                        onVoiceSelected: (voice) {
                                          provider.setSelectedVoice(
                                            voice.voiceId,
                                            voice.name,
                                          );
                                        },
                                      ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            provider.selectedVoiceId != null
                                                ? AppColors.textColor
                                                : Colors.grey.shade700,
                                        width: 1.5,
                                      ),
                                      color:
                                          provider.selectedVoiceId != null
                                              ? AppColors.textColor.withOpacity(
                                                0.1,
                                              )
                                              : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        provider.selectedVoiceId != null
                                            ? (localeFlagEmoji[codeLang ??
                                                    'en_US'] ??
                                                '🎙️')
                                            : '🎙️',
                                        style: TextStyle(fontSize: 26.sp),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  SizedBox(
                                    width: 70.w,
                                    child: Text(
                                      provider.selectedVoiceName ?? 'Voice',
                                      style: TextStyle(
                                        color: AppColors.textColor.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 10.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (!_speechEnabled && !_isPaused) {
                                  var ava = await _speechToText.initialize();
                                  if (ava) {
                                    setState(() {
                                      _speechEnabled = true;
                                      _speechToText.listen(
                                        onResult: (res) {
                                          setState(() {
                                            _partialText = res.recognizedWords;
                                            if (res.finalResult) {
                                              descriptionController.text +=
                                                  ' ${res.recognizedWords}';
                                              _partialText = "";
                                            }
                                          });
                                        },
                                        cancelOnError: false,
                                        partialResults: true,
                                        listenMode: ListenMode.confirmation,
                                        localeId:
                                            getLanguagesLocaleWithCodeForTextToSpeech(
                                              codeLang.toString(),
                                            ),
                                      );
                                    });
                                  } else {
                                    Get.snackbar(
                                      'warningImage'.tr,
                                      'Microphone permission denied',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                } else if (_speechEnabled && !_isPaused) {
                                  setState(() {
                                    _speechEnabled = false;
                                    _isPaused = true;
                                    _speechToText.stop();
                                  });
                                } else if (_isPaused) {
                                  setState(() {
                                    _isPaused = false;
                                    _speechEnabled = true;
                                    _speechToText.listen(
                                      onResult: (res) {
                                        setState(() {
                                          _partialText = res.recognizedWords;
                                          if (res.finalResult) {
                                            descriptionController.text +=
                                                ' ${res.recognizedWords}';
                                            _partialText = "";
                                          }
                                        });
                                      },
                                      cancelOnError: false,
                                      partialResults: true,
                                      listenMode: ListenMode.confirmation,
                                      localeId:
                                          getLanguagesLocaleWithCodeForTextToSpeech(
                                            codeLang.toString(),
                                          ),
                                    );
                                  });
                                }
                              },
                              child:
                                  _speechEnabled
                                      ? AvatarGlow(
                                        glowColor: AppColors.textColor,
                                        duration: const Duration(seconds: 2),
                                        repeat: true,
                                        animate: true,
                                        glowCount: 3,
                                        glowRadiusFactor: 0.6,
                                        child: CircleAvatar(
                                          backgroundColor: AppColors.textColor,
                                          radius: 40.0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: SvgPicture.asset(
                                              AppImagesUrls.microphone,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ),
                                      )
                                      : CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.black,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: SvgPicture.asset(
                                            AppImagesUrls.microphoneOff,
                                            color: AppColors.textColor,
                                            height: 50.h,
                                          ),
                                        ),
                                      ),
                            ),
                            _isProcessing
                                ? SizedBox(
                                  width: 50.w,
                                  height: 50.h,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textColor,
                                      ),
                                    ),
                                  ),
                                )
                                : IconButton(
                                  onPressed:
                                      (provider.isLoading ||
                                              provider.rxRequestStatus ==
                                                  CheckStatus.loading ||
                                              provider.communityRequestStatus ==
                                                  CheckStatus.loading)
                                          ? null
                                          : () async {
                                            if (_isProcessing) return;

                                            if (descriptionController
                                                .text
                                                .isEmpty) {
                                              Get.snackbar(
                                                'warningImage'.tr,
                                                'warningFelids'.tr,
                                                colorText: AppColors.textColor,
                                              );
                                            } else {
                                              setState(
                                                () => _isProcessing = true,
                                              );

                                              if (provider.isCommuinty) {
                                                final String conversationId =
                                                    'sapere-${DateTime.now().microsecondsSinceEpoch}';

                                                String? prompt =
                                                    provider
                                                        .bukBukTypeModel
                                                        .prompts[codeLang];
                                                provider.getCommunityResponse(
                                                  systemPrompt:
                                                      prompt.toString(),
                                                  userPrompt:
                                                      descriptionController
                                                          .text,
                                                  id: conversationId,
                                                  languageCode:
                                                      codeLang.toString(),
                                                );

                                                Get.back(); // Use Get.back() for safety
                                                Get.dialog(
                                                  const CreationMotivatorDialog(),
                                                  barrierDismissible: true,
                                                );
                                              } else {
                                                ///Normal
                                                final uid =
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid;
                                                final hasActive = await provider
                                                    .checkStoryStatus(uid);

                                                if (!mounted) return;

                                                if (hasActive) {
                                                  setState(
                                                    () => _isProcessing = false,
                                                  );
                                                  Get.snackbar(
                                                    'warningImage'.tr,
                                                    'audioRequestAlready'.tr,
                                                    backgroundColor: Colors.red,
                                                    colorText:
                                                        AppColors.whiteColor,
                                                    duration: const Duration(
                                                      seconds: 6,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                String? prompt =
                                                    provider
                                                        .bukBukTypeModel
                                                        .prompts[codeLang];
                                                provider.generateFullStory(
                                                  systemPrompt:
                                                      prompt.toString(),
                                                  baseUserPrompt:
                                                      descriptionController
                                                          .text,
                                                  languageCode:
                                                      codeLang.toString(),
                                                );

                                                Get.back(); // Use Get.back() for safety
                                                Get.dialog(
                                                  const CreationMotivatorDialog(),
                                                  barrierDismissible: true,
                                                );
                                              }

                                              // Reset processing after a short delay to allow navigation
                                              // or if we stay on page (e.g. error)
                                              Future.delayed(
                                                const Duration(seconds: 2),
                                                () {
                                                  if (mounted) {
                                                    setState(
                                                      () =>
                                                          _isProcessing = false,
                                                    );
                                                  }
                                                },
                                              );
                                            }
                                          },
                                  icon: Icon(
                                    Icons.arrow_forward,
                                    size: 50,
                                    color:
                                        (provider.isLoading ||
                                                provider.rxRequestStatus ==
                                                    CheckStatus.loading ||
                                                provider.communityRequestStatus ==
                                                    CheckStatus.loading)
                                            ? Colors.grey
                                            : AppColors.textColor,
                                  ),
                                ),
                          ],
                        ),
                      ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.textColor,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'creandoSapere'.tr,
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
