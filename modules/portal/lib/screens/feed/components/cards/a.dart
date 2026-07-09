import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/middle_mouse_gesture.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlexCardWidget extends ConsumerWidget {
  final dynamic ad;
  final String tag;
  final String mainImageUrl;
  final bool isPro;
  final bool isDefaultDarkSystem;
  final Color color;
  final Color textColor;
  final Color textFieldColor;
  final Widget buildShimmerPlaceholder;
  final dynamic buildPieMenuActions;
  final double aspectRatio;
  final bool isMobile;

  const AlexCardWidget({
    super.key,
    required this.ad,
    required this.tag,
    required this.mainImageUrl,
    required this.isPro,
    required this.isDefaultDarkSystem,
    required this.color,
    required this.textColor,
    required this.textFieldColor,
    required this.buildShimmerPlaceholder,
    required this.buildPieMenuActions,
    required this.aspectRatio,
    required this.isMobile,
  });

  static final NumberFormat _priceFmt = NumberFormat.decimalPattern('fr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.read(navigationService).currentPath;
    final path = currentPath == '/' ? '' : currentPath;



    final locationParts = <String>[
      if (ad.street.trim().isNotEmpty) ad.street.trim(),
      if (ad.district.trim().isNotEmpty) ad.district.trim(),
      if (ad.city.trim().isNotEmpty) ad.city.trim(),
      if (ad.state.trim().isNotEmpty) ad.state.trim(),
    ];

    final baseTextSize = 12.sp;
    final theme = ref.read(themeColorsProvider);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: MiddleClickDetector(
        onMiddleClick: () {
          debugPrint('Middle click detected!');
          handleBrowseListAction(ref, ad, context);
        },
        child: PieMenu(
          theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
          onPressedWithDevice: (kind) {
            if (kind == PointerDeviceKind.mouse ||
                kind == PointerDeviceKind.touch) {
              handleDisplayedAction(ref, ad.id, context);
              ref.read(navigationService).openPopup(
                '$path/offer/${ad.slug}',
                data: {'tag': tag, 'ad': ad},
              );
            }
          },
          actions: buildPieMenuActions,
          child: Hero(
            tag: tag,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13.r),
                border: isPro
                    ? Border.all(color: AppColors.light, width: 3.0)
                    : Border.all(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dpr = MediaQuery.of(context).devicePixelRatio;
                        final cardWidth = constraints.maxWidth;
                        final cardHeight = cardWidth / aspectRatio;

                        final memW =
                        (cardWidth * dpr).round().clamp(200, 1200);
                        final memH =
                        (cardHeight * dpr).round().clamp(200, 1200);

                        final diskW =
                        (cardWidth * 2).round().clamp(200, 1024);
                        final diskH =
                        (cardHeight * 2).round().clamp(200, 1024);

                        return CachedNetworkImage(
                          imageUrl: mainImageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          memCacheWidth: memW,
                          memCacheHeight: memH,
                          maxWidthDiskCache: diskW,
                          maxHeightDiskCache: diskH,
                          placeholder: (context, url) => buildShimmerPlaceholder,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey,
                            alignment: Alignment.center,
                            child: Text(
                              'No picture'.tr,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                    if (isPro)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 8.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Sponsored'.tr,
                                style: AppTextStyles.interMedium12dark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.h,
                          horizontal: 8.w,
                        ),
                        decoration: BoxDecoration(
                          color: isDefaultDarkSystem
                              ? textFieldColor.withAlpha((255 * 0.5).toInt())
                              : color.withAlpha((255 * 0.5).toInt()),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                '${_priceFmt.format(ad.price)} ${ad.currency}',
                                style: AppTextStyles.interBold.copyWith(
                                  fontSize: 18.sp,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                ad.title,
                                style: AppTextStyles.interSemiBold.copyWith(
                                  color: textColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child:

                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              locationParts.join(', '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.interLight.copyWith(
                                                color: theme.textColor,
                                                fontSize: baseTextSize,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
