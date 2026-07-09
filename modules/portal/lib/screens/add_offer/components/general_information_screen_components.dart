import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';

class CustomDropdownNoBackground extends ConsumerWidget {
  final List<String> options;
  final TextEditingController controller;
  final void Function(String?) onChanged;

  const CustomDropdownNoBackground({
    super.key,
    required this.options,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.primaryBackgroundTextColor.withAlpha(204),
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: DropdownButton<String>(
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(10),
        value: controller.text.isEmpty ? options!.first : controller.text,
        items:
            options
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: CustomColors.gradientTextcolor(context, ref),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        style: TextStyle(
          color: theme.primaryBackgroundTextColor.withAlpha(204),
        ),
        selectedItemBuilder: (BuildContext context) {
          return options.map((String value) {
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                value,
                style: TextStyle(
                  color: CustomColors.gradientTextcolor(context, ref),
                ),
              ),
            );
          }).toList();
        },
        icon: AppIcons.iosArrowDown(color: theme.primaryBackgroundTextColor),
        dropdownColor: CustomColors.adCardColor(context, ref),
        underline: Container(),
      ),
    );
  }
}

class ToggleButtonOptionAddOffer extends ConsumerWidget {
  final String label;
  final String value;
  final VoidCallback onPressed;

  const ToggleButtonOptionAddOffer({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final bool isSelected = value == 'Yes';

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color:
            isSelected ? theme.primaryBackgroundTextColor : Colors.transparent,
        border: Border.all(color: theme.primaryBackgroundTextColor),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? theme.whitewhiteblack
                    : theme.primaryBackgroundTextColor,
          ),
        ),
      ),
    );
  }
}
