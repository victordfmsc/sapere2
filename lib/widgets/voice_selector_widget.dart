import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/constant/const.dart';
import 'package:sapere/core/constant/voice_data.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sapere/core/services/eleven_lab_services.dart';
import 'package:flutter/services.dart';

/// A bottom sheet widget for selecting a voice from the ElevenLabs catalog.
/// Shows 5 voice cards per language with flag emoji, name, and tagline.
class VoiceSelectorWidget extends StatefulWidget {
  final String localeCode;
  final String? currentVoiceId;
  final ValueChanged<VoiceOption> onVoiceSelected;

  const VoiceSelectorWidget({
    super.key,
    required this.localeCode,
    required this.onVoiceSelected,
    this.currentVoiceId,
  });

  @override
  State<VoiceSelectorWidget> createState() => _VoiceSelectorWidgetState();
}

class _VoiceSelectorWidgetState extends State<VoiceSelectorWidget> {
  late String _selectedVoiceId;
  late List<VoiceOption> _voices;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingVoiceId;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _voices = getVoicesForLocale(widget.localeCode);
    _selectedVoiceId = widget.currentVoiceId ?? _voices.first.voiceId;

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(VoiceOption voice) async {
    if (_playingVoiceId == voice.voiceId) {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
        });
      }
      return;
    }

    // Stop existing playback
    await _audioPlayer.stop();
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _playingVoiceId = voice.voiceId;
        _isLoadingPreview = true;
      });
    }

    try {
      final phrase =
          localePreviewPhrases[widget.localeCode] ??
          localePreviewPhrases['en_US']!;

      final file = await ElevenLabsService().generateAudioFromText(
        phrase,
        voiceId: voice.voiceId,
      );

      if (_playingVoiceId == voice.voiceId) {
        await _audioPlayer.play(DeviceFileSource(file.path));
      }
    } catch (e) {
      print('Preview error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate preview')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langName = getLanguageName(widget.localeCode);
    final flag = localeFlagEmoji[widget.localeCode] ?? '🌍';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.blackColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header with flag and language name
          Row(
            children: [
              Text(flag, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Voice',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      langName,
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.6),
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Voice cards list
          SizedBox(
            height: 150.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _voices.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final voice = _voices[index];
                final isSelected = voice.voiceId == _selectedVoiceId;
                return _buildVoiceCard(voice, isSelected);
              },
            ),
          ),
          SizedBox(height: 20.h),
          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {
                final selected = _voices.firstWhere(
                  (v) => v.voiceId == _selectedVoiceId,
                );
                widget.onVoiceSelected(selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textColor,
                foregroundColor: AppColors.blackColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm Voice',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildVoiceCard(VoiceOption voice, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVoiceId = voice.voiceId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 140.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.textColor.withOpacity(0.12)
                  : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.textColor : Colors.grey.shade800,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.textColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flag + selected indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(voice.flagEmoji, style: TextStyle(fontSize: 26.sp)),
                _isLoadingPreview && _playingVoiceId == voice.voiceId
                    ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textColor,
                      ),
                    )
                    : GestureDetector(
                      onTap: () => _togglePreview(voice),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color:
                              _playingVoiceId == voice.voiceId
                                  ? Colors.red.withOpacity(0.2)
                                  : AppColors.textColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _playingVoiceId == voice.voiceId
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color:
                              _playingVoiceId == voice.voiceId
                                  ? Colors.red
                                  : AppColors.textColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                if (isSelected && _playingVoiceId != voice.voiceId)
                  Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      color: AppColors.textColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.blackColor,
                      size: 14.sp,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Voice name
            Text(
              voice.name,
              style: TextStyle(
                color:
                    isSelected
                        ? AppColors.textColor
                        : AppColors.textColor.withOpacity(0.85),
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            // Tagline
            Text(
              voice.tagline,
              style: TextStyle(
                color:
                    isSelected
                        ? AppColors.textColor.withOpacity(0.7)
                        : Colors.grey.shade500,
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
