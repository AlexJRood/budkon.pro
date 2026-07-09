import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class SimpleAdCard extends ConsumerWidget {
  final double itemWidth;
  final double itemHeight;
  final double baseTextSize;
  final double paddingDynamic;
  final int index;
  final dynamic displayedAd;

  const SimpleAdCard({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    required this.baseTextSize,
    required this.paddingDynamic,
    required this.index,
    required this.displayedAd,
  });

  // 🔹 Reuse formatter instead of creating on every build
  static final NumberFormat _priceFormatter =
  NumberFormat.decimalPattern('fr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String formattedPrice = _priceFormatter.format(displayedAd.price);

    // 🔹 Stable hero tag (no UniqueKey allocation each rebuild)
    final String tag = 'recentlyViewed6-${displayedAd.id}';

    final String mainImageUrl = displayedAd.images.isNotEmpty
        ? displayedAd.images[0]
        : 'https://i.pinimg.com/1200x/d0/f8/78/d0f878e457ee6254b07bfb928886941d.jpg';

    final currentPath = ref.read(navigationService).currentPath;
    final path = currentPath == '/' ? '' : currentPath;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final memWidth = (itemWidth * devicePixelRatio).round();
    final memHeight = (itemHeight * devicePixelRatio).round();

    return PieMenu(
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
          ref.read(navigationService).openPopup(
            '$path/offer/${displayedAd.slug}',
            data: {'tag': tag, 'ad': displayedAd},
          );
        }
      },
      actions: buildPieMenuActions(ref, displayedAd, context),
      child: Hero(
        tag: tag,
        child: Container(
          width: itemWidth,
          height: itemHeight,
          margin: EdgeInsets.only(
            left: index == 0 ? paddingDynamic : 0,
            right: baseTextSize,
          ),
          // 🔹 Single clipping for everything inside
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 🔹 One image widget, no extra Container+Decoration layer
                CachedNetworkImage(
                  imageUrl: mainImageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  memCacheWidth: memWidth,
                  memCacheHeight: memHeight,
                  maxWidthDiskCache: (itemWidth * 2).round(),
                  maxHeightDiskCache: (itemHeight * 2).round(),
                  placeholder: (context, url) => ShimmerPlaceholder(
                    width: itemWidth,
                    height: itemHeight,
                  ),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.error),
                ),

                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      end: Alignment.topRight,
                      begin: Alignment.bottomLeft,
                      colors: [AppColors.dark50, AppColors.dark15],
                    ),
                  ),
                ),

                // Text overlay
                Positioned(
                  left: 8,
                  bottom: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$formattedPrice ${displayedAd.currency}',
                        style: AppTextStyles.interBold.copyWith(
                          fontSize: baseTextSize,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        '${displayedAd.city}, ${displayedAd.street}',
                        style: AppTextStyles.interRegular.copyWith(
                          fontSize: baseTextSize - 2,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
