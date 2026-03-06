import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sapere/core/constant/colors.dart';
import 'package:sapere/providers/learning_provider.dart';
import 'dart:math';

class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isBackVisible = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(_flipController);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBackVisible) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isBackVisible = !_isBackVisible;
    });
  }

  void _nextCard(bool correct) {
    final provider = Provider.of<LearningProvider>(context, listen: false);
    final card = provider.dueCards[_currentIndex];

    provider.answerCard(card, correct);

    if (_currentIndex < provider.dueCards.length - 1) {
      setState(() {
        _currentIndex++;
        _isBackVisible = false;
        _flipController.reset();
      });
    } else {
      _showSessionComplete();
    }
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xff1C1C1E),
            title: const Text(
              "¡Repaso Completado!",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 64.sp),
                SizedBox(height: 16.h),
                const Text(
                  "Has reforzado tus conocimientos. ¡Sigue así!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Finalizar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        title: const Text(
          "Sesión de Repaso",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<LearningProvider>(
        builder: (context, provider, child) {
          if (provider.dueCards.isEmpty) {
            return const Center(
              child: Text(
                "No hay más tarjetas por hoy",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final card = provider.dueCards[_currentIndex];
          final progress = (_currentIndex + 1) / provider.dueCards.length;

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textColor,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  minHeight: 6.h,
                ),
                SizedBox(height: 12.h),
                Text(
                  "REPASO: ${_currentIndex + 1} / ${provider.dueCards.length}",
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.5),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value;
                          return Transform(
                            transform:
                                Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                            alignment: Alignment.center,
                            child:
                                angle < pi / 2
                                    ? _buildCardFace(card.question, "Pregunta")
                                    : Transform(
                                      transform:
                                          Matrix4.identity()..rotateY(pi),
                                      alignment: Alignment.center,
                                      child: _buildCardFace(
                                        card.answer,
                                        "Respuesta",
                                        isAnswer: true,
                                      ),
                                    ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_isBackVisible) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        "Difícil",
                        Colors.redAccent,
                        () => _nextCard(false),
                      ),
                      _buildActionButton(
                        "Fácil",
                        Colors.greenAccent,
                        () => _nextCard(true),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    "Toca la tarjeta para ver la respuesta",
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace(String text, String label, {bool isAnswer = false}) {
    return Container(
      width: double.infinity,
      height: 400.h,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color:
              isAnswer
                  ? Colors.greenAccent.withOpacity(0.4)
                  : AppColors.textColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color:
                  isAnswer
                      ? Colors.greenAccent.withOpacity(0.1)
                      : AppColors.textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isAnswer ? Colors.greenAccent : AppColors.textColor,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(height: 40.h),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          if (!isAnswer)
            Icon(Icons.touch_app, color: Colors.white24, size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return Container(
      width: 140.w,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
