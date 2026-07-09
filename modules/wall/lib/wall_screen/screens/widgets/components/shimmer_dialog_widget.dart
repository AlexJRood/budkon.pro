import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:core/theme/backgroundgradient.dart';
// import CustomColors as needed
import 'package:get/get_utils/get_utils.dart';
class LoadingShimmer extends ConsumerWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = CustomColors.secondaryWidgetColor(
      context,
      ref,
    ).withAlpha(102); // ✅ Changed from withValues to withOpacity

    final shimmerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        backgroundColor.withAlpha(76),
        backgroundColor.withAlpha(153),
      ],
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: shimmerGradient),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: backgroundColor.withAlpha(76),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitFadingCube(
                    color: CustomColors.secondaryWidgetTextColor(context, ref),
                    size: 40.0,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fetching media...'.tr,
                    style: TextStyle(
                      color: CustomColors.secondaryWidgetTextColor(
                        context,
                        ref,
                      ).withAlpha(217),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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
