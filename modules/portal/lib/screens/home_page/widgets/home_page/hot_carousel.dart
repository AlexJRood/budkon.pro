import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/home_page/providers/listing_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:shimmer/shimmer.dart';

class HotCarousel extends ConsumerWidget {
  const HotCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewedAdsAsyncValue = ref.watch(listingsProvider);
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1920 * 240;
    double itemheight = itemWidth * 3.59;

    itemWidth = max(150.0, min(itemWidth, 300.0));
    double minBaseTextSize = 14;
    double maxBaseTextSize = 18;
    double baseTextSize = minBaseTextSize +
        (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
    baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    final themecolors = ref.watch(themeColorsProvider);

    final textFieldColor = themecolors.textFieldColor;
    final textColor = themecolors.themeTextColor;
    final colorscheme = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
          'hot_offers'.tr,
            style: AppTextStyles.interSemiBold18.copyWith(color: textColor),
          ),
        ),
        const SizedBox(height: 20),
        recentlyViewedAdsAsyncValue.when(
          data: (displayedAds) => CarouselSlider.builder(
            itemCount: displayedAds.length,
            options: CarouselOptions(
              enlargeCenterPage: true,
              aspectRatio: 2.2,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            itemBuilder: (context, index, realIndex) {
              if (displayedAds.isEmpty) {
                return const SizedBox.shrink();
              }
              final ad = displayedAds[index];
              final tag = 'hotOffer233_${ad.id}_$index-${UniqueKey().toString()}';
              final formattedPrice = customFormat.format(ad.price);
              final mainImageUrl =
                  ad.images.isNotEmpty ? ad.images[0] : 'default_image_url';

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
                    handleDisplayedAction(ref, ad.id, context);
                    ref.read(navigationService).pushNamedScreen(
                      '${Routes.entry}/${ad.id}',
                      data: {'tag': tag, 'ad': ad},
                    );

                    // ref.read(navigationService).pushNamedScreen(
                    //   '${Routes.ad}/${ad.id}',
                    //   data: {'tag': tag, 'ad': ad},
                    // );
                  }
                },
                actions: buildPieMenuActions(ref, ad, context),
                child: Hero(
                  tag: tag,
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: mainImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: ShimmerColors.base(context),
                          highlightColor: ShimmerColors.highlight(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: ShimmerColors.background(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 5, right: 8, left: 8),
                          decoration: BoxDecoration(
                            color: isDefaultDarkSystem
                                ? textFieldColor.withAlpha((255 * 0.5).toInt())
                                : colorscheme.withAlpha((255 * 0.5).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$formattedPrice ${ad.currency}',
                                style: AppTextStyles.interBold.copyWith(
                                    fontSize: baseTextSize + 2,
                                    color: textColor),
                              ),
                              Text(
                                ad.title,
                                style: AppTextStyles.interSemiBold.copyWith(
                                    fontSize: baseTextSize, color: textColor),
                              ),
                              Text(
                                '${ad.city}, ${ad.street}',
                                style: AppTextStyles.interRegular.copyWith(
                                    fontSize: baseTextSize - 2,
                                    color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => Carouselloading(
            height: itemheight,
          ),
          error: (error, stackTrace) => Text('${'An error occurred'.tr}: $error'.tr,
              style: AppTextStyles.interMedium.copyWith(color: textColor)),
        ),
      ],
    );
  }

  ImageConfiguration createImageConfiguration(BuildContext context) {
    return ImageConfiguration(
      bundle: DefaultAssetBundle.of(context),
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      locale: Localizations.localeOf(context),
      textDirection: Directionality.of(context),
      size: MediaQuery.of(context).size,
      platform: Theme.of(context).platform,
    );
  }
}
