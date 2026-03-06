import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sapere/core/constant/colors.dart';

class PrimaryButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final double? width;
  final bool isLoading;
  final double? height;
  final double? elevation;
  final double borderRadius;
  final double? fontSize;
  final IconData? iconData;
  final Color? textColor, bgColor;
  final List<Color>? gradient;

  const PrimaryButton({
    super.key,
    required this.onTap,
    required this.text,
    this.width,
    this.height,
    this.elevation,
    this.isLoading = false,
    this.borderRadius = 16,
    this.fontSize,
    required this.textColor,
    required this.bgColor,
    this.iconData,
    this.gradient,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Duration _animationDuration = const Duration(milliseconds: 200);
  final Tween<double> _tween = Tween<double>(begin: 1.0, end: 0.96);

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _tween.animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        ),
        child: Container(
          height: widget.height ?? 54.h,
          width: widget.width ?? double.maxFinite,
          decoration: BoxDecoration(
            color: widget.gradient == null ? widget.bgColor : null,
            gradient:
                widget.gradient != null
                    ? LinearGradient(
                      colors: widget.gradient!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient?.first ??
                        widget.bgColor ??
                        Colors.black)
                    .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              widget.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : IntrinsicWidth(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.iconData != null) ...[
                          Icon(
                            widget.iconData,
                            color: widget.textColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.fontSize ?? 16.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
