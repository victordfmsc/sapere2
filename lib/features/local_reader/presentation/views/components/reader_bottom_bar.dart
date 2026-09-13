import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/local_reader_controller.dart';
import 'reader_palette.dart';

/// Barra flotante de transporte: anterior, play/pause, siguiente, velocidad y progreso.
class ReaderBottomBar extends StatelessWidget {
  final LocalReaderController controller;

  static const rates = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  const ReaderBottomBar({super.key, required this.controller});

  static String rateLabel(double r) {
    final s = r.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
    return 'x$s';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final settings = controller.settings.value;
      final palette = ReaderPalette.of(settings.theme);
      final book = controller.book.value;
      final total = book?.sentences.length ?? 0;
      final current = controller.currentSentence.value;
      final progress = total == 0 ? 0.0 : ((current + 1) / total).clamp(0.0, 1.0);
      final percent = (progress * 100).round().toString();
      final playing = controller.isPlaying.value;

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: palette.text.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(palette.isDark ? 0.5 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3.h,
                      backgroundColor: palette.text.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'readerProgress'.trParams({'p': percent}),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: palette.text.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SpeedChip(
                  rate: settings.rate,
                  palette: palette,
                  onSelected: controller.setRate,
                ),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('reader_prev_button'),
                      onPressed: controller.previous,
                      icon: Icon(Icons.skip_previous_rounded,
                          color: palette.text, size: 30.sp),
                    ),
                    SizedBox(width: 4.w),
                    Material(
                      color: palette.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const ValueKey('reader_play_button'),
                        customBorder: const CircleBorder(),
                        onTap: controller.togglePlay,
                        child: SizedBox(
                          width: 56.r,
                          height: 56.r,
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: palette.isDark
                                ? palette.background
                                : Colors.white,
                            size: 34.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      key: const ValueKey('reader_next_button'),
                      onPressed: controller.next,
                      icon: Icon(Icons.skip_next_rounded,
                          color: palette.text, size: 30.sp),
                    ),
                  ],
                ),
                SizedBox(width: 56.w),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SpeedChip extends StatelessWidget {
  final double rate;
  final ReaderPalette palette;
  final ValueChanged<double> onSelected;

  const _SpeedChip({
    required this.rate,
    required this.palette,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      key: const ValueKey('reader_speed_chip'),
      tooltip: 'readerSpeed'.tr,
      color: palette.surface,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final r in ReaderBottomBar.rates)
          PopupMenuItem<double>(
            value: r,
            child: Text(
              ReaderBottomBar.rateLabel(r),
              style: TextStyle(
                color: palette.text,
                fontWeight: (r - rate).abs() < 0.01
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        width: 56.w,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: palette.text.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          ReaderBottomBar.rateLabel(rate),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}
