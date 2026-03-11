import 'package:flutter/material.dart';
import 'package:sapere/core/constant/colors.dart';

Future<void> showLoadingDialog(BuildContext context, {String? message}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.textColor),
                const SizedBox(height: 16),
                Text(
                  message ?? "Loading...",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}
