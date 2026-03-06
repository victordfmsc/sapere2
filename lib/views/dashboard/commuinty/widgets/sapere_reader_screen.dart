import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/core/services/local_storage_service.dart';
import 'package:sapere/providers/history_provider.dart';
import 'package:sapere/models/post.dart';
import '../../../../routes/app_pages.dart';

class SapereReaderScreen extends StatefulWidget {
  final String? postId; // Added to support history
  final String title;
  final String content;
  final String? audioUrl;
  final String? coverUrl;
  final double? initialOffset;

  const SapereReaderScreen({
    super.key,
    this.postId,
    required this.title,
    required this.content,
    this.audioUrl,
    this.coverUrl,
    this.initialOffset,
  });

  @override
  State<SapereReaderScreen> createState() => _SapereReaderScreenState();
}

class _SapereReaderScreenState extends State<SapereReaderScreen> {
  double _fontSize = 18.0;
  String _fontFamily = 'Serif';
  Color _themeColor = const Color(0xFF121212);
  Color _textColor = Colors.white;
  late ScrollController _scrollController;
  Timer? _progressTimer;

  // Local storage keys
  static const String _fsKey = 'reader_font_size';
  static const String _ffKey = 'reader_font_family';
  static const String _themeKey = 'reader_theme_index';

  final List<Map<String, dynamic>> _themes = [
    {'bg': Colors.white, 'text': Colors.black, 'name': 'Light'},
    {'bg': const Color(0xFF1A1B1E), 'text': Colors.white, 'name': 'Dark'},
    {
      'bg': const Color(0xFF0D2B22),
      'text': const Color(0xFFD4E3DD),
      'name': 'Green',
    },
    {
      'bg': const Color(0xFFF2D1C9),
      'text': const Color(0xFF4A342E),
      'name': 'Peach',
    },
  ];

  final List<String> _fonts = ['Serif', 'Sans-serif', 'Monospace', 'Georgia'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialOffset ?? 0.0,
    );
    _loadSettings();

    // Save progress periodically if postId is available
    if (widget.postId != null) {
      _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _saveProgress();
      });
    }
  }

  @override
  void dispose() {
    if (widget.postId != null) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveProgress() {
    if (widget.postId == null) return;

    final historyProvider = Provider.of<HistoryProvider>(
      context,
      listen: false,
    );
    // Note: We need a BukBukPost to save progress, but we only have title/content here.
    // In a real scenario, we should pass the full post.
    // For now, I'll create a dummy post or the HistoryProvider should be adapted.
    // Looking at HistoryProvider.saveTextProgress, it takes a BukBukPost.
    // I'll assume for now we use the ID and just enough data.

    historyProvider.saveTextProgress(
      BukBukPost(
        postId: widget.postId,
        sapereName: widget.title,
        newCover: widget.coverUrl,
      ),
      _scrollController.offset,
    );
  }

  Future<void> _loadSettings() async {
    final storage = LocalStorage();
    final fs = await storage.getData(key: _fsKey);
    final ff = await storage.getData(key: _ffKey);
    final th = await storage.getData(key: _themeKey);

    if (mounted) {
      setState(() {
        if (fs != null) _fontSize = double.tryParse(fs) ?? 18.0;
        if (ff != null) _fontFamily = ff;
        if (th != null) {
          int index = int.tryParse(th) ?? 1;
          _themeColor = _themes[index]['bg'];
          _textColor = _themes[index]['text'];
        } else {
          // Default to Dark Mode index 1
          _themeColor = _themes[1]['bg'];
          _textColor = _themes[1]['text'];
        }
      });
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    await LocalStorage().setData(key: key, value: value);
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(20.w),
              height: 350.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Text('Aa', style: TextStyle(fontSize: 14.sp)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14,
                          max: 32,
                          activeColor: AppColors.kSamiOrange,
                          onChanged: (val) {
                            setModalState(() => _fontSize = val);
                            setState(() => _fontSize = val);
                            _saveSetting(_fsKey, val.toString());
                          },
                        ),
                      ),
                      Text('Aa', style: TextStyle(fontSize: 24.sp)),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          _fonts.map((f) {
                            bool selected = _fontFamily == f;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => _fontFamily = f);
                                setState(() => _fontFamily = f);
                                _saveSetting(_ffKey, f);
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Column(
                                  children: [
                                    Text(
                                      'Aa',
                                      style: TextStyle(
                                        fontFamily:
                                            f == 'Serif'
                                                ? 'serif'
                                                : (f == 'Sans-serif'
                                                    ? 'sans-serif'
                                                    : (f == 'Monospace'
                                                        ? 'monospace'
                                                        : 'serif')),
                                        fontSize: 20.sp,
                                        color:
                                            selected
                                                ? AppColors.kSamiOrange
                                                : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      f,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color:
                                            selected
                                                ? AppColors.kSamiOrange
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_themes.length, (index) {
                      bool selected = _themeColor == _themes[index]['bg'];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _themeColor = _themes[index]['bg'];
                            _textColor = _themes[index]['text'];
                          });
                          setState(() {
                            _themeColor = _themes[index]['bg'];
                            _textColor = _themes[index]['text'];
                          });
                          _saveSetting(_themeKey, index.toString());
                        },
                        child: Container(
                          width: 45.w,
                          height: 45.w,
                          decoration: BoxDecoration(
                            color: _themes[index]['bg'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected
                                      ? AppColors.kSamiOrange
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: AppColors.kSamiOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = "";
    String remainingText = widget.content;

    if (widget.content.isNotEmpty) {
      firstLetter = widget.content.substring(0, 1);
      remainingText = widget.content.substring(1);
    }

    TextStyle bodyStyle = TextStyle(
      fontSize: _fontSize.sp,
      color: _textColor,
      height: 1.6,
      fontFamily:
          _fontFamily == 'Serif'
              ? 'serif'
              : (_fontFamily == 'Sans-serif'
                  ? 'sans-serif'
                  : (_fontFamily == 'Monospace' ? 'monospace' : 'serif')),
    );

    return Scaffold(
      backgroundColor: _themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.audioUrl != null)
            TextButton.icon(
              onPressed: () {
                // Open audio player with current post data
                final post = BukBukPost(
                  postId: widget.postId,
                  sapereName: widget.title,
                  newCover: widget.coverUrl,
                  sapereUrl: widget.audioUrl,
                );

                Get.toNamed(Routes.audioPlayer, arguments: post);
              },
              icon: Icon(Icons.play_arrow, color: _textColor, size: 20.sp),
              label: Text(
                "play".tr,
                style: TextStyle(color: _textColor, fontSize: 14.sp),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _textColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          SizedBox(width: 10.w),
        ],
      ),
      body: GestureDetector(
        onTap: _showSettings,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (_fontSize + 6).sp,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: Container(
                        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: (_fontSize * 3.5).sp,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                            height: 0.8,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: remainingText, style: bodyStyle),
                  ],
                ),
              ),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
