import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuestionTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function onPressed;

  const QuestionTextField({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.black),
        maxLines: null,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(10),
          hintText: "WriteComment".tr,
          fillColor: Colors.white,
          filled: true,
          hintStyle: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          suffixIcon: SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      onPressed();
                    },
                    child: Icon(
                      Icons.send,
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
