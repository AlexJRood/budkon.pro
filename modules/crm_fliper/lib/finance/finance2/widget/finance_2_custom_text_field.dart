import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

class Finance2CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const Finance2CustomTextField(
      {super.key,
        this.hintText = "Search...",
        this.onChanged,
        this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding:  EdgeInsets.symmetric(horizontal: 10.w),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText.tr,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
