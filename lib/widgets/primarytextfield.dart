import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PrimaryTextFormField extends StatefulWidget {
  const PrimaryTextFormField({
    super.key,
    required this.hintText,
    this.keyboardType,
    required this.controller,
    this.hintTextColor = const Color(0xffB0B0B0),
    this.onChanged,
    this.onTapOutside,
    this.inputFormatters,
    this.isSuffixIcon = false,
    this.maxLines,
    this.onTab,
    required this.labelText,
    this.borderRadius,
    this.validator,
    this.suffixIconWidget,
  });

  final double? borderRadius;
  final Widget? suffixIconWidget;
  final String hintText, labelText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Function(PointerDownEvent)? onTapOutside;
  final Function(String)? onChanged;
  final void Function()? onTab;
  final TextEditingController controller;
  final Color hintTextColor;
  final TextInputType? keyboardType;
  final bool isSuffixIcon;
  final int? maxLines;

  @override
  State<PrimaryTextFormField> createState() => _PrimaryTextFormFieldState();
}

class _PrimaryTextFormFieldState extends State<PrimaryTextFormField> {
  bool isFocusNode = false;
  FocusNode? focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode!.addListener(_onFocusChange);
  }

  _onFocusChange() {
    setState(() {
      isFocusNode = focusNode!.hasFocus;
    });
  }

  @override
  void dispose() {
    focusNode!.removeListener(_onFocusChange);
    focusNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme appTextStyle = Theme.of(context).textTheme;

    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      focusNode: focusNode,
      keyboardType: widget.keyboardType,
      cursorColor: AppColors.primaryColor,
      style: appTextStyle.titleMedium!.copyWith(color: AppColors.textColor),
      decoration: InputDecoration(
        fillColor: Colors.transparent,
        filled: true,
        label: Text(widget.labelText.tr),
        labelStyle: appTextStyle.titleMedium!.copyWith(
          color: AppColors.textColor,
        ),
        hintText: widget.hintText.tr,
        hintStyle: appTextStyle.labelSmall!.copyWith(
          color: widget.hintTextColor,
        ),
        suffixIcon: widget.isSuffixIcon ? widget.suffixIconWidget : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: AppColors.primaryColor.withOpacity(0.5), width: 1.0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
      ),
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      onTapOutside: widget.onTapOutside ??
          (e) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
      onTap: widget.onTab,
      validator: widget.validator,
    );
  }
}
