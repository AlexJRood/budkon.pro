import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:portal/browselist/components/card.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/feed/provider/feed_pop/similarads_provider.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/lottie.dart';

class SimilarAds extends ConsumerStatefulWidget {
  final String offerid;

  const SimilarAds({super.key, required this.offerid});

  @override
  ConsumerState<SimilarAds> createState() => _SimilarAdsState();
}

class _SimilarAdsState extends ConsumerState<SimilarAds> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final similaradProvider = ref.watch(similarProvider(widget.offerid));

    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / 1500 * 350;
    itemWidth = max(150.0, min(itemWidth, 350.0));
    double itemHeight = itemWidth;

    double minBaseTextSize = 12;
    double maxBaseTextSize = 16;
    double baseTextSize =
        minBaseTextSize +
        (itemWidth - 150) / (240 - 150) * (maxBaseTextSize - minBaseTextSize);
    baseTextSize = max(minBaseTextSize, min(baseTextSize, maxBaseTextSize));
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');
    final themecolors = ref.watch(themeColorsProvider);
    final textColor = themecolors.themeTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
             'similar_listings'.tr,
              style: AppTextStyles.interSemiBold.copyWith(
                fontSize: baseTextSize + 6,
                color: themecolors.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        similaradProvider.when(
          data:
              (similarOffers) {
                if (similarOffers.isEmpty) {
                  return Center(
                      child: AppLottie.noResults()
                  );
                }
           return DragScrollView(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        similarOffers.map((similarOffers) {
                          String formattedPrice = customFormat.format(
                            similarOffers.price,
                          );
                          final tag =
                              'SimilarAds${similarOffers.id}-${UniqueKey().toString()}';
                          final mainImageUrl =
                              similarOffers.images.isNotEmpty
                                  ? similarOffers.images[0]
                                  : '';

                          return SizedBox(
                            width: itemWidth,
                            child: PortalBrowseListCardWidget(
                              isHidden: false,
                              feedAd: similarOffers,
                              isMobile: true,
                              keyTag: tag,
                              aspectRatio: 4 / 4,
                              isUnorganizedProperties: true,
                              mainImageUrl: mainImageUrl,
                              formattedPrice: formattedPrice,
                              isFeedPop: true,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              );},
          loading:
              () => ShimmerLoadingRow(
                itemWidth: itemWidth,
                itemHeight: itemHeight,
                placeholderwidget: ShimmerPlaceholder(
                  width: itemWidth,
                  height: itemHeight,
                ),
              ),
          error:
              (error, stack) => Center(
                child: Text(
                  '${'An error occurred'.tr}: $error'.tr,
                  style: AppTextStyles.interRegular.copyWith(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
