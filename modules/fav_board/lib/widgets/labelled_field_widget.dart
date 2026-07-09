import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class LabelledFieldWidget extends ConsumerWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const LabelledFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide.none,
    );

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(color: theme.textColor, fontSize: 13)),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:  TextStyle(color: theme.textColor),
            prefixIcon: prefixIcon, // 👈 No manual padding
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: theme.adPopBackground,
            border: border,
            focusedBorder: border,
            disabledBorder: border,
            enabledBorder: border,
          ),
          style:  TextStyle(color: theme.textColor),
        ),
      ],
    );
  }
}
