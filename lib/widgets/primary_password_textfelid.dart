// ignore_for_file: library_private_types_in_public_api

import 'package:sapere/core/constant/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordTextField extends StatefulWidget {
  final String hintText;

  final TextEditingController controller;

  final String labelText;
  final String? Function(String?)? validator;
  const PasswordTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    this.validator,
  });
  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
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
    InputBorder enabledBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
    );
    InputBorder focusedErrorBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
    );
    InputBorder errorBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
    );
    InputBorder focusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
    );

    return TextFormField(
      obscureText: _obscureText,
      controller: widget.controller,
      style: appTextStyle.titleMedium!.copyWith(color: AppColors.textColor),
      onTapOutside: (e) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      focusNode: focusNode,
      decoration: InputDecoration(
        fillColor: Colors.transparent,
        label: Text(widget.labelText),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
        labelStyle: appTextStyle.titleMedium!.copyWith(
          color: AppColors.textColor,
        ),
        hintText: widget.hintText,
        hintStyle: appTextStyle.labelSmall!.copyWith(
          color: AppColors.textColor,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textColor,
            size: 20.sp,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: widget.validator,
    );
  }
}
