import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/sapere_provider.dart';
import 'package:sapere/core/constant/voice_data.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/widgets/voice_selector_widget.dart';
import 'package:sapere/core/constant/strings.dart';

class PreviewCreationDialog extends StatefulWidget {
  const PreviewCreationDialog({super.key});

  @override
  State<PreviewCreationDialog> createState() => _PreviewCreationDialogState();
}

class _PreviewCreationDialogState extends State<PreviewCreationDialog> {
  final TextEditingController _ideaController = TextEditingController();
  bool _isGenerating = false;
  String? codeLang;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final storedLang = await LocalStorage().getData(
      key: AppLocalKeys.localeKey,
    );
    if (mounted) {
      setState(() {
        codeLang = storedLang ?? 'en_US';
      });
    }
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.kSamiOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.kSamiOrange,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "crearPreview".tr, // Add to translations
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "previewIncentive".tr, // "Free 30s summary of your idea"
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),

              // Voice Selector
              Consumer<BukBukProvider>(
                builder: (context, provider, child) {
                  return GestureDetector(
                    onTap: () {
                      if (codeLang == null) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (_) => VoiceSelectorWidget(
                              localeCode: codeLang!,
                              currentVoiceId: provider.selectedVoiceId,
                              onVoiceSelected: (voice) {
                                provider.setSelectedVoice(
                                  voice.voiceId,
                                  voice.name,
                                );
                              },
                            ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            provider.selectedVoiceId != null
                                ? (localeFlagEmoji[codeLang ?? 'en_US'] ??
                                    '🎙️')
                                : '🎙️',
                            style: TextStyle(fontSize: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "voz".tr,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                Text(
                                  provider.selectedVoiceName ?? 'Select Voice',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              TextField(
                controller: _ideaController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "ideaHintText".tr,
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
              SizedBox(height: 24.h),
              _isGenerating
                  ? CircularProgressIndicator(color: AppColors.kSamiOrange)
                  : Column(
                    children: [
                      _buildActionButton(
                        label: "generateFree".tr,
                        onTap: _handleGenerate,
                        isPrimary: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildActionButton(
                        label: "cancelar".tr,
                        onTap: () => Get.back(),
                        isPrimary: false,
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient:
              isPrimary
                  ? LinearGradient(colors: AppColors.kGoldGradient)
                  : null,
          color: isPrimary ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: isPrimary ? null : Border.all(color: Colors.white24),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _handleGenerate() async {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) {
      Get.snackbar("warning".tr, "warningFelids".tr);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final provider = Provider.of<BukBukProvider>(context, listen: false);
      final localeProvider = Get.locale?.toString() ?? 'en_US';

      await provider.createPreviewPost(
        prompt: idea,
        languageCode: localeProvider,
        voiceId: provider.selectedVoiceId,
      );

      Get.back(); // Close dialog
      Get.snackbar(
        "success".tr,
        "creandoSapere".tr,
        backgroundColor: AppColors.kSamiOrange.withOpacity(0.7),
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      Get.snackbar("Error", e.toString());
    }
  }
}
