import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:get/get_utils/get_utils.dart';

class MediaErrorContent extends ConsumerWidget {
  const MediaErrorContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.red[900]!.withAlpha(76),
        Colors.red[800]!.withAlpha(128),
      ],
    );

    final backgroundColor = CustomColors.secondaryWidgetColor(context, ref);
    final textColor = CustomColors.secondaryWidgetTextColor(context, ref);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                color: textColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load media'.tr,
              style: TextStyle(
                color: textColor.withAlpha(230),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection'.tr,
              style: TextStyle(
                color: textColor.withAlpha(178),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
