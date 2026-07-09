import 'dart:math';
import 'package:get/get_utils/get_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';

class HelpBar extends ConsumerWidget {
  const HelpBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1920 * 240;
    itemWidth = max(150.0, min(itemWidth, 300.0));

    double minBaseTextSize = 12;
    double maxBaseTextSize = 20;
    double baseTextSize = minBaseTextSize +
        (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
    baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('how_can_we_help_you_today'.tr,
            style: AppTextStyles.interSemiBold.copyWith(
                fontSize: 16, color: Theme.of(context).iconTheme.color)),
        const SizedBox(height: 10.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              HelpButton('i_am_selling'.tr, onPressed: () {
                ref.read(navigationService).pushNamedReplacementScreen(
                      Routes.sellPage,
                    );
              }),
              SizedBox(width: baseTextSize),
              HelpButton('i_am_buying'.tr, onPressed: () {
                // Implementuj odpowiednią akcję dla przycisku "Kupuję".tr
              }),
              SizedBox(width: baseTextSize),
              HelpButton('i_am_renting'.tr, onPressed: () {
                // Implementuj odpowiednią akcję dla przycisku "Wynajmuję".tr
              }),
              SizedBox(width: baseTextSize),
              HelpButton('i_am_building'.tr, onPressed: () {
                // Implementuj odpowiednią akcję dla przycisku "I’m building".tr
              }),
              SizedBox(width: baseTextSize),
              HelpButton('i_am_investing'.tr, onPressed: () {
                // Implementuj odpowiednią akcję dla przycisku "Inwestuję".tr
              }),
              SizedBox(width: baseTextSize),
              HelpButton('inheritance'.tr, onPressed: () {
                // Implementuj odpowiednią akcję dla przycisku "Spadek".tr
              }),
              // Dodaj więcej przycisków HelpButton według potrzeb
            ],
          ),
        ),
      ],
    );
  }
}

class HelpButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;

  const HelpButton(this.text, {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context,ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1920 * 350;
    itemWidth = max(100.0, min(itemWidth, 300.0));

    double minBaseTextSize = 12;
    double maxBaseTextSize = 16;
    double baseTextSize = minBaseTextSize +
        (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
    baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));

    return Container(
      decoration: BoxDecoration(
        gradient: CustomBackgroundGradients.getbuttonGradient1(context, ref),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5.0),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: baseTextSize * 1.5, vertical: baseTextSize / 2.5),
            child: Text(text,
                style: AppTextStyles.interMedium.copyWith(
                    fontSize: baseTextSize,
                    color: Theme.of(context).iconTheme.color)),
          ),
        ),
      ),
    );
  }
}
