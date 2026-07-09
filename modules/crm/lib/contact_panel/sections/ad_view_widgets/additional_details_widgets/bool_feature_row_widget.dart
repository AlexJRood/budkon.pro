import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class BoolFeatureRow extends StatelessWidget {
  const BoolFeatureRow({
    super.key,
    required this.label,
    required this.isEditing,
    required this.theme,
    required this.controller,
  });

  final String label;
  final bool isEditing;
  final ThemeColors theme;
  final ValueNotifier<bool> controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: value || isEditing ? 1 : 0.86,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: isEditing ? () => controller.value = !value : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: value
                    ? theme.themeColor.withAlpha(35)
                    : theme.dashboardContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value
                      ? theme.themeColor
                      : theme.textFieldColor.withAlpha(140),
                  width: value ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    value
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: value
                        ? theme.themeColor
                        : theme.textColor.withAlpha(170),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.interRegular.copyWith(
                        fontSize: 14,
                        color: theme.textColor,
                        fontWeight:
                        value ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: value
                          ? theme.themeColor.withAlpha(25)
                          : theme.textFieldColor.withAlpha(70),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      (value ? 'Yes'.tr : 'No'.tr),
                      style: AppTextStyles.interRegular.copyWith(
                        fontSize: 11,
                        color: value
                            ? theme.themeColor
                            : theme.textColor.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ),
        );
      },
    );
  }
}