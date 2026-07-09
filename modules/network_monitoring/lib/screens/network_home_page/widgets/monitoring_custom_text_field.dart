import 'package:flutter/material.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';



class MonitoringCustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const MonitoringCustomTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final String effectiveHint = hintText ?? 'Search...'.tr;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: effectiveHint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: AppIcons.search(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
    );
  }
}
