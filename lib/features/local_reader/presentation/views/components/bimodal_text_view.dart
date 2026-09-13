import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../models/local_book.dart';
import '../../../models/text_segment.dart';
import '../../controllers/local_reader_controller.dart';
import 'reader_palette.dart';

/// Texto del libro con resaltado de oración y palabra sincronizado con la voz.
class BimodalTextView extends StatefulWidget {
  final LocalReaderController controller;
  final ScrollController scrollController;
  final void Function(int sentenceIndex) onSentenceTap;

  const BimodalTextView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onSentenceTap,
  });

  @override
  State<BimodalTextView> createState() => _BimodalTextViewState();
}

class _BimodalTextViewState extends State<BimodalTextView> {
  static const _userScrollPause = Duration(seconds: 4);

  final List<Worker> _workers = [];
  final Map<int, GlobalKey> _paragraphKeys = {};
  List<List<TextSentence>> _byParagraph = const [];
  String? _indexedBookId;
  DateTime _autoScrollPausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _programmaticScroll = false;
  bool _initialScrollDone = false;

  LocalReaderController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _workers.add(ever<LocalBook?>(controller.book, (_) => _onBookChanged()));
    _workers.add(ever<int>(controller.currentSentence, _onSentenceChanged));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- índices

  void _indexBook(LocalBook book) {
    if (_indexedBookId == book.id && _byParagraph.length == book.paragraphs.length) {
      return;
    }
    final grouped = List<List<TextSentence>>.generate(
      book.paragraphs.length,
      (_) => <TextSentence>[],
    );
    for (final s in book.sentences) {
      if (s.paragraphIndex >= 0 && s.paragraphIndex < grouped.length) {
        grouped[s.paragraphIndex].add(s);
      }
    }
    _byParagraph = grouped;
    _paragraphKeys.clear();
    _indexedBookId = book.id;
  }

  GlobalKey _keyFor(int paragraph) =>
      _paragraphKeys.putIfAbsent(paragraph, GlobalKey.new);

  int? _paragraphOfSentence(int sentenceIndex) {
    final book = controller.book.value;
    if (book == null) return null;
    if (sentenceIndex < 0 || sentenceIndex >= book.sentences.length) return null;
    return book.sentences[sentenceIndex].paragraphIndex;
  }

  // ----------------------------------------------------------------- scroll

  void _onBookChanged() {
    _initialScrollDone = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
  }

  void _scrollToInitial() {
    if (_initialScrollDone || !mounted) return;
    final book = controller.book.value;
    if (book == null || book.sentences.isEmpty) return;
    _initialScrollDone = true;
    if (controller.currentSentence.value > 0) {
      unawaited(_revealSentence(controller.currentSentence.value,
          alignment: 0.3, duration: Duration.zero));
    }
  }

  void _onSentenceChanged(int index) {
    if (!mounted) return;
    if (!controller.settings.value.autoScroll) return;
    if (!controller.isPlaying.value) return;
    if (DateTime.now().isBefore(_autoScrollPausedUntil)) return;
    unawaited(_revealSentence(index,
        alignment: 0.35, duration: const Duration(milliseconds: 250)));
  }

  Future<void> _revealSentence(int sentenceIndex,
      {required double alignment, required Duration duration}) async {
    final paragraph = _paragraphOfSentence(sentenceIndex);
    if (paragraph == null) return;
    if (_keyFor(paragraph).currentContext == null) {
      // El párrafo aún no está construido (ListView perezoso): saltamos a una
      // posición estimada y reintentamos en el siguiente frame.
      final sc = widget.scrollController;
      if (!sc.hasClients || _byParagraph.isEmpty) return;
      final fraction = paragraph / _byParagraph.length;
      _programmaticScroll = true;
      sc.jumpTo((sc.position.maxScrollExtent * fraction)
          .clamp(0.0, sc.position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
      _programmaticScroll = false;
    }
    if (!mounted) return;
    final target = _keyFor(paragraph).currentContext;
    if (target == null || !target.mounted) return;
    _programmaticScroll = true;
    try {
      await Scrollable.ensureVisible(
        target,
        alignment: alignment,
        duration: duration,
        curve: Curves.easeOut,
      );
    } finally {
      _programmaticScroll = false;
    }
  }

  bool _onScrollNotification(UserScrollNotification n) {
    if (_programmaticScroll) return false;
    if (n.direction != ScrollDirection.idle) {
      _autoScrollPausedUntil = DateTime.now().add(_userScrollPause);
    }
    return false;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final book = controller.book.value;
      final settings = controller.settings.value;
      final palette = ReaderPalette.of(settings.theme);
      if (book == null) return const SizedBox.shrink();
      _indexBook(book);

      final list = NotificationListener<UserScrollNotification>(
        onNotification: _onScrollNotification,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: settings.horizontalMargin.w,
            vertical: 16.h,
          ),
          itemCount: _byParagraph.length,
          itemBuilder: (context, i) => _ParagraphView(
            key: _keyFor(i),
            paragraphIndex: i,
            sentences: _byParagraph[i],
            controller: controller,
            onSentenceTap: widget.onSentenceTap,
          ),
        ),
      );

      if (settings.maskLines <= 0) return list;
      return Stack(
        children: [
          list,
          Positioned.fill(
            child: IgnorePointer(
              child: _ReadingMask(
                windowHeight:
                    settings.fontSize.sp * settings.lineHeight * settings.maskLines,
                color: palette.background.withOpacity(0.82),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ReadingMask extends StatelessWidget {
  final double windowHeight;
  final Color color;

  const _ReadingMask({required this.windowHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final band = ((constraints.maxHeight - windowHeight) / 2).clamp(
        0.0,
        constraints.maxHeight,
      );
      return Column(
        children: [
          Container(height: band, color: color),
          const Spacer(),
          Container(height: band, color: color),
        ],
      );
    });
  }
}

class _ParagraphView extends StatefulWidget {
  final int paragraphIndex;
  final List<TextSentence> sentences;
  final LocalReaderController controller;
  final void Function(int sentenceIndex) onSentenceTap;

  const _ParagraphView({
    super.key,
    required this.paragraphIndex,
    required this.sentences,
    required this.controller,
    required this.onSentenceTap,
  });

  @override
  State<_ParagraphView> createState() => _ParagraphViewState();
}

class _SentenceRange {
  final int start;
  final int end;
  final int sentenceIndex;
  const _SentenceRange(this.start, this.end, this.sentenceIndex);
}

class _ParagraphViewState extends State<_ParagraphView> {
  final GlobalKey _textKey = GlobalKey();
  List<_SentenceRange> _ranges = const [];

  void _onTapUp(TapUpDetails d) {
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph) return;
    final offset = render.getPositionForOffset(d.localPosition).offset;
    for (final r in _ranges) {
      if (offset >= r.start && offset < r.end) {
        widget.onSentenceTap(r.sentenceIndex);
        return;
      }
    }
    if (_ranges.isNotEmpty) widget.onSentenceTap(_ranges.last.sentenceIndex);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Obx(() {
      final settings = controller.settings.value;
      final palette = ReaderPalette.of(settings.theme);
      final active = controller.currentSentence.value;
      final showMarker = controller.showResumeMarker.value;

      final hasActive = widget.sentences.any((s) => s.indexInBook == active);
      final activeWord = hasActive ? controller.currentWord.value : null;

      final base = TextStyle(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.sp,
        height: settings.lineHeight,
        color: palette.text,
      );
      final dimmed = base.copyWith(color: palette.text.withOpacity(0.35));

      final spans = <InlineSpan>[];
      final ranges = <_SentenceRange>[];
      var cursor = 0;
      for (var i = 0; i < widget.sentences.length; i++) {
        final s = widget.sentences[i];
        final isActive = s.indexInBook == active;
        if (i > 0) {
          spans.add(TextSpan(text: ' ', style: base));
          cursor += 1;
        }
        final style = isActive
            ? base.copyWith(backgroundColor: palette.sentenceHighlight)
            : (settings.focusMode ? dimmed : base);
        spans.add(TextSpan(
          style: style,
          children: _sentenceSpans(s, isActive ? activeWord : null, style, palette),
        ));
        ranges.add(_SentenceRange(cursor, cursor + s.text.length, s.indexInBook));
        cursor += s.text.length;
      }
      _ranges = ranges;

      final text = GestureDetector(
        key: ValueKey('reader_paragraph_${widget.paragraphIndex}'),
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        child: Padding(
          padding: EdgeInsets.only(bottom: settings.fontSize.sp * 0.9),
          child: RichText(
            key: _textKey,
            textAlign: TextAlign.left,
            text: TextSpan(style: base, children: spans),
          ),
        ),
      );

      if (!showMarker || !hasActive) return text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResumeMarker(palette: palette),
          text,
        ],
      );
    });
  }

  List<InlineSpan> _sentenceSpans(TextSentence s, int? activeWord,
      TextStyle style, ReaderPalette palette) {
    if (s.words.isEmpty) return [TextSpan(text: s.text)];
    final out = <InlineSpan>[];
    var pos = 0;
    for (var w = 0; w < s.words.length; w++) {
      final token = s.words[w];
      if (token.start > pos) out.add(TextSpan(text: s.text.substring(pos, token.start)));
      final isWord = activeWord == w;
      out.add(TextSpan(
        text: s.text.substring(token.start, token.end),
        style: isWord
            ? style.copyWith(
                backgroundColor: palette.wordHighlight,
                color: palette.wordText,
                fontWeight: FontWeight.w600,
              )
            : null,
      ));
      pos = token.end;
    }
    if (pos < s.text.length) out.add(TextSpan(text: s.text.substring(pos)));
    return out;
  }
}

class _ResumeMarker extends StatelessWidget {
  final ReaderPalette palette;

  const _ResumeMarker({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('reader_resume_marker'),
      padding: EdgeInsets.only(bottom: 6.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: palette.accent.withOpacity(palette.isDark ? 0.18 : 0.14),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: palette.accent.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_rounded, size: 14.sp, color: palette.accent),
            SizedBox(width: 6.w),
            Text(
              'readerResumeHere'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
