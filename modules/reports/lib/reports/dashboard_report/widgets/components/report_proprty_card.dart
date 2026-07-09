import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';

import 'dart:math' as math;
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/backgroundgradient.dart';

class ReprtPropertyCard extends StatelessWidget {
  final String imageUrl;
  final String address;
  final int reportId;
  final String price;
  final bool isMobile;
  final WidgetRef ref;
  final bool isBlur;
  final Color? backgroundColor;
  final bool isTablet;

  const ReprtPropertyCard({
    super.key,
    required this.imageUrl,
    required this.address,
    required this.reportId,
    required this.price,
    this.isMobile = false,
    required this.ref,
    this.isBlur = true,
    this.backgroundColor,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);

    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth =
        screenWidth <= 1920
            ? 380.0
            : math.min(screenWidth * 0.15, 1200).toDouble();

    final double containerHeight =
        screenWidth <= 1920
            ? 200
            : math.min(1200, 200 + (screenWidth - 1920) * 0.1);

    return PieMenu(
      actions: [],
      onPressed: () {
        nav.openPopup(
          Routes.reportResultDetails(reportId),
        );
        
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: isTablet ? 180 : containerHeight,
          width:isMobile
        ? 276
            : isTablet
        ? (screenWidth / 3) - 20
            : containerWidth,
          color: Colors.black12,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  height: 200,
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: CustomColors.gradientTextcolor(context, ref),
                        alignment: Alignment.center,
                        child: Text(
                          'No Image'.tr,
                          style: TextStyle(
                            color: CustomColors.gradientTextcolor(context, ref),
                          ),
                        ),
                      ),
                ),
              ),
      
              // Bottom Blur or Colored Info Box
              Positioned(
                bottom: -5,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  child:
                      isBlur
                          ? BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: _infoContent(
                              context,
                              theme,
                              CustomColors.adCardColor(
                                context,
                                ref,
                              ).withAlpha(102),
                            ),
                          )
                          : _infoContent(
                            context,
                            theme,
                            backgroundColor ??
                                CustomColors.adCardColor(context, ref),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoContent(BuildContext context, ThemeColors theme, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
           'report'.tr,
            style: TextStyle(
              color: theme.bordercolor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CustomColors.gradientTextcolor(context, ref),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Spacer(),
              Text(
                price,
                style: TextStyle(
                  color: CustomColors.gradientTextcolor(context, ref),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
