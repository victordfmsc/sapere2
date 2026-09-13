import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../models/local_voice.dart';
import '../../../models/reader_settings.dart';
import '../../../services/background_audio_service.dart';
import '../../controllers/local_reader_controller.dart';
import 'reader_palette.dart';

/// Hoja de ajustes del lector: Texto, Voz y Sonido.
Future<void> showTypographySheet(
  BuildContext context,
  LocalReaderController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TypographySheet(controller: controller),
  );
}

class _TypographySheet extends StatelessWidget {
  final LocalReaderController controller;

  const _TypographySheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final palette = ReaderPalette.of(controller.settings.value.theme);
      final theme = ThemeData(
        brightness: palette.brightness,
        colorSchemeSeed: palette.accent,
        useMaterial3: true,
      );
      return Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: palette.text,
            displayColor: palette.text,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              clipBehavior: Clip.antiAlias,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: palette.text.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    TabBar(
                      labelColor: palette.accent,
                      unselectedLabelColor: palette.text.withOpacity(0.6),
                      indicatorColor: palette.accent,
                      tabs: [
                        Tab(text: 'readerTypography'.tr),
                        Tab(text: 'readerVoice'.tr),
                        Tab(text: 'readerAmbient'.tr),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TextTab(
                            controller: controller,
                            scrollController: scrollController,
                          ),
                          _VoiceTab(controller: controller),
                          _SoundTab(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h, bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(label),
            Text(display, style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TextTab extends StatelessWidget {
  final LocalReaderController controller;
  final ScrollController scrollController;

  const _TextTab({required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.settings.value;
      final palette = ReaderPalette.of(s.theme);
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        children: [
          _SectionTitle('readerFont'.tr),
          Wrap(
            spacing: 8.w,
            children: [
              for (final f in ReaderSettings.fontFamilies)
                ChoiceChip(
                  key: ValueKey('reader_font_$f'),
                  label: Text(f, style: TextStyle(fontFamily: f)),
                  selected: s.fontFamily == f,
                  onSelected: (_) =>
                      controller.updateSettings((x) => x.copyWith(fontFamily: f)),
                ),
            ],
          ),
          _LabeledSlider(
            label: 'readerFontSize'.tr,
            value: s.fontSize,
            min: 14,
            max: 30,
            divisions: 16,
            display: s.fontSize.round().toString(),
            onChanged: (v) => controller
                .updateSettings((x) => x.copyWith(fontSize: v.roundToDouble())),
          ),
          _LabeledSlider(
            label: 'readerLineHeight'.tr,
            value: s.lineHeight,
            min: 1.2,
            max: 2.0,
            divisions: 8,
            display: s.lineHeight.toStringAsFixed(1),
            onChanged: (v) => controller.updateSettings(
                (x) => x.copyWith(lineHeight: (v * 10).round() / 10)),
          ),
          _LabeledSlider(
            label: 'readerMargins'.tr,
            value: s.horizontalMargin,
            min: 12,
            max: 40,
            divisions: 28,
            display: s.horizontalMargin.round().toString(),
            onChanged: (v) => controller.updateSettings(
                (x) => x.copyWith(horizontalMargin: v.roundToDouble())),
          ),
          _SectionTitle('readerTheme'.tr),
          Row(
            children: [
              for (final t in ReaderSettings.themes) ...[
                _ThemeSwatch(
                  id: t,
                  selected: s.theme == t,
                  onTap: () =>
                      controller.updateSettings((x) => x.copyWith(theme: t)),
                ),
                SizedBox(width: 14.w),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          SwitchListTile(
            key: const ValueKey('reader_focus_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text('readerFocusMode'.tr, style: TextStyle(fontSize: 14.sp)),
            value: s.focusMode,
            onChanged: (v) =>
                controller.updateSettings((x) => x.copyWith(focusMode: v)),
          ),
          _SectionTitle('readerReadingMask'.tr),
          SegmentedButton<int>(
            segments: [
              for (final n in ReaderSettings.maskLineOptions)
                ButtonSegment<int>(
                  value: n,
                  label: Text(
                    n == 0
                        ? 'readerMaskOff'.tr
                        : 'readerMaskLines'.trParams({'n': '$n'}),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
            ],
            selected: {s.maskLines},
            showSelectedIcon: false,
            onSelectionChanged: (sel) => controller
                .updateSettings((x) => x.copyWith(maskLines: sel.first)),
          ),
          SwitchListTile(
            key: const ValueKey('reader_autoscroll_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text('readerAutoScroll'.tr, style: TextStyle(fontSize: 14.sp)),
            value: s.autoScroll,
            activeColor: palette.accent,
            onChanged: (v) =>
                controller.updateSettings((x) => x.copyWith(autoScroll: v)),
          ),
        ],
      );
    });
  }
}

class _ThemeSwatch extends StatelessWidget {
  final String id;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = ReaderPalette.of(id);
    return InkWell(
      key: ValueKey('reader_theme_$id'),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: p.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? p.accent : p.text.withOpacity(0.3),
            width: selected ? 3 : 1,
          ),
        ),
        child: Center(
          child: selected
              ? Icon(Icons.check, color: p.text, size: 20.sp)
              : Text('Aa',
                  style: TextStyle(color: p.text, fontSize: 14.sp)),
        ),
      ),
    );
  }
}

class _VoiceTab extends StatelessWidget {
  final LocalReaderController controller;

  const _VoiceTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.settings.value;
      final palette = ReaderPalette.of(s.theme);
      final loading = controller.voicesLoading.value;
      final voices = controller.availableVoices;
      final selected = controller.selectedVoice.value;

      return ListView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        children: [
          _LabeledSlider(
            label: 'readerSpeed'.tr,
            value: s.rate,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            display: 'x${s.rate.toStringAsFixed(2)}',
            onChanged: controller.setRate,
          ),
          _SectionTitle('readerVoices'.tr),
          if (loading)
            Padding(
              padding: EdgeInsets.all(20.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (voices.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('readerNoVoices'.tr,
                  style: TextStyle(fontSize: 13.sp)),
            )
          else
            for (final v in voices)
              _VoiceTile(
                voice: v,
                selected: v == selected,
                palette: palette,
                onSelect: () => controller.selectVoice(v),
                onPreview: () => controller.previewVoice(v),
              ),
        ],
      );
    });
  }
}

class _VoiceTile extends StatelessWidget {
  final LocalVoice voice;
  final bool selected;
  final ReaderPalette palette;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const _VoiceTile({
    required this.voice,
    required this.selected,
    required this.palette,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('reader_voice_${voice.id}'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onSelect,
      leading: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? palette.accent : palette.text.withOpacity(0.4),
      ),
      title: Text(
        voice.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13.sp),
      ),
      subtitle: Row(
        children: [
          Text(voice.locale, style: TextStyle(fontSize: 11.sp)),
          if (voice.isNeural) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: palette.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'HD',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: TextButton.icon(
        onPressed: onPreview,
        icon: Icon(Icons.volume_up_rounded, size: 16.sp),
        label: Text('readerPreviewVoice'.tr, style: TextStyle(fontSize: 11.sp)),
      ),
    );
  }
}

class _SoundTab extends StatelessWidget {
  final LocalReaderController controller;

  const _SoundTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.settings.value;
      final sfxAvailable = controller.sfx?.hasAssets == true;
      return ListView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        children: [
          _SectionTitle('readerAmbient'.tr),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              ChoiceChip(
                key: const ValueKey('reader_ambient_off'),
                label: Text('readerAmbientOff'.tr),
                selected: s.ambientTrackId == null,
                onSelected: (_) => controller.setAmbient(null),
              ),
              for (final t in ambientTracks)
                ChoiceChip(
                  key: ValueKey('reader_ambient_${t.id}'),
                  avatar: Image.asset(t.icon, width: 20.w, height: 20.w),
                  label: Text(t.nameKey.tr),
                  selected: s.ambientTrackId == t.id,
                  onSelected: (_) => controller.setAmbient(t.id),
                ),
            ],
          ),
          _LabeledSlider(
            label: 'readerAmbientVolume'.tr,
            value: s.ambientVolume,
            min: 0,
            max: 1,
            divisions: 10,
            display: '${(s.ambientVolume * 100).round()}%',
            onChanged: controller.setAmbientVolume,
          ),
          SwitchListTile(
            key: const ValueKey('reader_sfx_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text('readerSfx'.tr, style: TextStyle(fontSize: 14.sp)),
            value: s.sfxEnabled && sfxAvailable,
            onChanged: sfxAvailable
                ? (v) =>
                    controller.updateSettings((x) => x.copyWith(sfxEnabled: v))
                : null,
          ),
        ],
      );
    });
  }
}
