import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:portal/widgets/landing_page_pc/components/category_buttons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:portal/screens/home_page/providers/listing_provider.dart';
import 'package:core/common/loading_widgets.dart';

import 'package:get/get_utils/get_utils.dart';


import '../../../../enum/landing_ads_tab.dart';
import '../../../../global_providers/landing_page_ads_provider.dart';
import 'package:core/theme/lottie.dart';
// Define a StateProvider to manage the selected tab
final selectedRecentlyViewedCategoryProvider =
StateProvider<LandingAdsTab>(
      (ref) => LandingAdsTab.recentlyViewed,
);


final selectedLandingSectionTabProvider =
StateProvider<LandingAdsTab>((ref) => LandingAdsTab.newListing);

class ExclusiveOffersWidget extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isTablet;

  const ExclusiveOffersWidget({
    super.key,
    required this.paddingDynamic,
    this.isTablet = false,
  });

  @override
  ConsumerState<ExclusiveOffersWidget> createState() =>
      _ExclusiveOffersWidgetState();
}

class _ExclusiveOffersWidgetState extends ConsumerState<ExclusiveOffersWidget> {
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
    final selectedTab = ref.watch(selectedLandingSectionTabProvider);
    final listingProvider = ref.watch(landingPageAdsProvider(selectedTab));
    final dynamicVerticalPadding = widget.paddingDynamic / 6;
    final theme = ref.watch(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    return Padding(
      padding: EdgeInsets.only(
        bottom: dynamicVerticalPadding,
        top: dynamicVerticalPadding / 2.5,
      ),
      child: SizedBox(
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: widget.paddingDynamic,
                      right: widget.paddingDynamic,
                    ),
                    child: CategorySelector(
                      isTablet: widget.isTablet,
                      selectedCategory: selectedTab.trLabel(),
                      onCategorySelected: (category) {
                        final mappedTab = [
                          LandingAdsTab.newListing,
                          LandingAdsTab.exclusiveOffers,
                          LandingAdsTab.openHouses,
                          LandingAdsTab.mostViewed,
                        ].firstWhere(
                              (tab) => tab.trLabel() == category,
                          orElse: () => LandingAdsTab.exclusiveOffers,
                        );

                        ref.read(selectedLandingSectionTabProvider.notifier).state =
                            mappedTab;
                      },
                      tabs: [
                        LandingAdsTab.newListing.trLabel(),
                        LandingAdsTab.exclusiveOffers.trLabel(),
                        LandingAdsTab.openHouses.trLabel(),
                        LandingAdsTab.mostViewed.trLabel(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: widget.paddingDynamic),
                  child: Row(
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
                      const SizedBox(width: 20),
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
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: widget.paddingDynamic),
                child: listingProvider.when(
                  data: (adsList) {
                    if (adsList.isEmpty) {
                      return Center(child: AppLottie.noResults(size: 450));
                    }

                    return DragScrollView(
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: adsList.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return SizedBox(width: widget.paddingDynamic);
                          }

                          final ad = adsList[index - 1];
                          final tag =
                              'landing-${ad.id}-${UniqueKey().toString()}';

                          return SelectedCardWidget(
                            isFeed: true,
                            isMobile: false,
                            aspectRatio: 4 / 3,
                            ad: ad,
                            tag: tag,
                            mainImageUrl: ad.images.isNotEmpty ? ad.images.last : '',
                            isPro: false,
                            isDefaultDarkSystem:
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark,
                            color: CustomColors.landingpagewidgetcolor(context, ref),
                            textColor: CustomColors.landingPageTextColor(context, ref),
                            textFieldColor:
                            CustomColors.landingPageSubHeadingColor(context, ref),
                            buildShimmerPlaceholder: const ShimmerPlaceholder(
                              width: 400,
                              height: 300,
                            ),
                            buildPieMenuActions: buildPieMenuActions(ref, ad, context),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => DragScrollView(
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
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
                  ),
                  error: (error, stackTrace) => SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: widget.paddingDynamic),
                        SizedBox(
                          width: itemWidth * 5,
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
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // TO DO: ADD TO VERSION 2.0

// // Footer Link
// Align(
//   alignment: Alignment.centerRight,
//   child: Padding(
//     padding: EdgeInsets.only(right: widget.paddingDynamic),
//     child: TextButton(
//       onPressed: () {},
//       child: Text(
//         'View more exclusive offers →'.tr,
//         style: TextStyle(
//           color: theme.textColor,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ),
//   ),
// ),
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



