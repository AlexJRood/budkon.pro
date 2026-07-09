import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/home_page/providers/listing_provider.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';

import 'package:get/get_utils/get_utils.dart';

class WhyUs extends ConsumerWidget {
  const WhyUs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewedAdsAsyncValue = ref.watch(listingsProvider);
    //final currentthememode = ref.watch(themeProvider);
    final themecolors = ref.watch(themeColorsProvider);

    final textColor = themecolors.themeTextColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            'Why Us'.tr,
            style: AppTextStyles.interSemiBold18.copyWith(color: textColor),
          ),
        ),
        const SizedBox(height: 20),
        recentlyViewedAdsAsyncValue.when(
          data: (displayedAds) => CarouselSlider.builder(
            itemCount: displayedAds.length,
            options: CarouselOptions(
              height: 400,
              enlargeCenterPage: true,
              aspectRatio: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            itemBuilder: (context, index, realIndex) {
              if (displayedAds.isEmpty) {
                return const SizedBox.shrink();
              }
              final ad = displayedAds[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CachedNetworkImage(
                  imageUrl: ad.images.isNotEmpty ? ad.images[0] : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
          loading: () => const Carouselloading(
            height: 400,
          ),
          error: (error, stackTrace) => Text('${'An error occurred'.tr}: $error'.tr,
              style: AppTextStyles.interMedium.copyWith(color: textColor)),
        ),
      ],
    );
  }
}
