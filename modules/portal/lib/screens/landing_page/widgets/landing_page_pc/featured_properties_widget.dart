import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';

import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/drad_scroll_widget.dart';

import 'package:portal/screens/home_page/providers/listing_provider.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';
import 'dart:math';

class FeaturedPropertiesWidget extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isMobile;

  const FeaturedPropertiesWidget({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
  });

  @override
  ConsumerState<FeaturedPropertiesWidget> createState() =>
      _FeaturedPropertiesWidgetState();
}

class _FeaturedPropertiesWidgetState
    extends ConsumerState<FeaturedPropertiesWidget> {
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
    final recentlyViewedAdsAsyncValue = ref.watch(listingsProvider);
    final dynamicVerticalPadding = widget.paddingDynamic / 3;
    final theme = ref.watch(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dynamicVerticalPadding),
      child: SizedBox(
        height: 401,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.paddingDynamic),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FEATURED PROPERTIES'.tr,
                    style: AppTextStyles.libreCaslonHeading.copyWith(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!widget.isMobile)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _scrollController.animateTo(
                              _scrollController.offset - 300,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: theme.textColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          onPressed: () {
                            _scrollController.animateTo(
                              _scrollController.offset + 300,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 24,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: widget.paddingDynamic),
                child: recentlyViewedAdsAsyncValue.when(
                  data: (adsList) {
                    if (adsList.isEmpty) {
                      return Center(
                        child: AppLottie.noResults(
                          size: widget.isMobile ? 200 : 450,
                        ),
                      );
                    }

                    return DragScrollView(
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        separatorBuilder:
                            (context, index) =>
                                index == 0
                                    ? SizedBox()
                                    : const SizedBox(width: 10),
                        itemCount:
                            adsList.length +
                            1, // Zwiększamy o 1, żeby dodać padding na początku
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return SizedBox(width: widget.paddingDynamic);
                          }
                          final ad = adsList[index - 1];
                          final tag =
                              'recentlyViewed2-${ad.id}-${UniqueKey().toString()}';

                          return SelectedCardWidget(
                            isMobile: false,
                            aspectRatio: 3 / 3,
                            ad: ad,
                            tag: tag,
                            mainImageUrl:
                                ad.images.isNotEmpty ? ad.images.last : '',
                            isPro: false,
                            isDefaultDarkSystem:
                                MediaQuery.of(context).platformBrightness ==
                                Brightness.dark,
                            color: CustomColors.landingpagewidgetcolor(
                              context,
                              ref,
                            ),
                            textColor: CustomColors.landingPageTextColor(
                              context,
                              ref,
                            ),
                            textFieldColor:
                                CustomColors.landingPageSubHeadingColor(
                                  context,
                                  ref,
                                ), 
                            buildShimmerPlaceholder: const ShimmerPlaceholder(
                              width: 400,
                              height: 300,
                            ),
                            buildPieMenuActions: buildPieMenuActions(
                              ref,
                              ad,
                              context,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () {
                    const shimmerItemCount = 6;

                    return DragScrollView(
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            shimmerItemCount +
                            1, // +1 because your list has padding at index 0
                        separatorBuilder:
                            (context, index) =>
                                index == 0
                                    ? SizedBox()
                                    : const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return SizedBox(width: widget.paddingDynamic);
                          }

                          return const ShimmerPlaceholder(
                            width: 400,
                            height: 300,
                          );
                        },
                      ),
                    );
                  },
                  error: (error, stackTrace) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final itemWidth = widget.isMobile
                             ? screenWidth * 0.78
                             : max(150.0, min(screenWidth / 1500 * 240, 250.0));
                    final itemHeight = widget.isMobile
                             ? itemWidth * 0.75 
                             : itemWidth * (300 / 260);
                    return SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: widget.paddingDynamic),
                        SizedBox(
                         width: widget.isMobile ? screenWidth - 32 : itemWidth * 5,
                          height: itemHeight,
                          child: Stack(
                            children: [
                              Shimmer.fromColors(
                                baseColor: ShimmerColors.base(context),
                                highlightColor: ShimmerColors.highlight(context),
                                child: Container(
                                  width: double.infinity,
                                  height: itemHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: ShimmerColors.background(context),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        (error is String)
                                            ? error
                                            : "Something Went Wrong".tr,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  
                        SizedBox(width: widget.paddingDynamic),
                      ],
                    ),
                  );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerPlaceholderWidget extends StatelessWidget {
  final double adFiledSize;
  final int crossAxisCount;

  const ShimmerPlaceholderWidget({
    super.key,
    required this.adFiledSize,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: adFiledSize,
      width: adFiledSize,
      child: ShimmerAdvertisementGrid(crossAxisCount: crossAxisCount),
    );
  }
}
