import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/local_reader_controller.dart';
import 'components/bimodal_text_view.dart';
import 'components/reader_bottom_bar.dart';
import 'components/reader_palette.dart';
import 'components/typography_sheet.dart';

/// Pantalla del lector bimodal (texto resaltado + voz).
class ReaderScreen extends StatefulWidget {
  final LocalReaderController controller;
  final bool autoPlay;
  final bool autoApplyAmbient;

  const ReaderScreen({
    super.key,
    required this.controller,
    this.autoPlay = false,
    this.autoApplyAmbient = true,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scroll = ScrollController();
  StreamSubscription<void>? _finishedSub;
  bool _left = false;

  LocalReaderController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _finishedSub = controller.coordinator.finished.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('readerFinished'.tr)),
      );
    });
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(controller.play());
      });
    }
  }

  Future<void> _leave() async {
    if (_left) return;
    _left = true;
    await controller.pause();
    await controller.saveProgressNow();
  }

  @override
  void dispose() {
    _finishedSub?.cancel();
    _scroll.dispose();
    unawaited(_leave());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_leave());
      },
      child: Obx(() {
        final palette = ReaderPalette.of(controller.settings.value.theme);
        final title = controller.book.value?.title ?? '';
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: palette.text,
            iconTheme: IconThemeData(color: palette.text),
            leading: IconButton(
              key: const ValueKey('reader_close_button'),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                key: const ValueKey('reader_settings_button'),
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => showTypographySheet(context, controller),
              ),
            ],
          ),
          body: BimodalTextView(
            controller: controller,
            scrollController: _scroll,
            onSentenceTap: (i) => unawaited(controller.jumpTo(i)),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: ReaderBottomBar(controller: controller),
          ),
        );
      }),
    );
  }
}
