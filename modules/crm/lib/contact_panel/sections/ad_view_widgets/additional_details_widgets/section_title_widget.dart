import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.theme});
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'additional_details_title'.tr,
      style: AppTextStyles.interBold.copyWith(
        fontSize: 20,
        color: theme.textColor,
      ),
    );
  }
}
