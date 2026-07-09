import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:portal/widgets/landing_page_pc/components/category_buttons.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import '../../../../enum/landing_ads_tab.dart';
import '../../../../global_providers/landing_page_ads_provider.dart';

final selectedMobileLandingSectionTabProvider = StateProvider<LandingAdsTab>(
  (ref) => LandingAdsTab.exclusiveOffers,
);

class ExclusiveOffersWidgetMobile extends ConsumerStatefulWidget {
  const ExclusiveOffersWidgetMobile({super.key});

  @override
  ConsumerState<ExclusiveOffersWidgetMobile> createState() =>
      _ExclusiveOffersWidgetMobileState();
}

class _ExclusiveOffersWidgetMobileState
    extends ConsumerState<ExclusiveOffersWidgetMobile> {
  late final ScrollController _scrollController;
  late final PageController _pageController;
  
  int _currentTabPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedMobileLandingSectionTabProvider);
    final listingProvider = ref.watch(landingPageAdsProvider(selectedTab));
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    final theme = ref.watch(themeColorsProvider);
    final allTabs = [
      LandingAdsTab.exclusiveOffers.trLabel(),
      LandingAdsTab.newListing.trLabel(),
      LandingAdsTab.openHouses.trLabel(),
      LandingAdsTab.mostViewed.trLabel(),
    ];
    
    final tabPages = [
      [allTabs[0], allTabs[1]],
      [allTabs[2], allTabs[3]], 
    ];
    
    return SizedBox(
      height: 490,
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentTabPage = page;
                  });
                },
                itemCount: tabPages.length,
                itemBuilder: (context, pageIndex) {
                  final currentTabs = tabPages[pageIndex];
                  
                  return CategorySelector(
                    isMobile: true,
                    selectedCategory: selectedTab.trLabel(),
                    onCategorySelected: (category) {
                      final mappedTab = [
                        LandingAdsTab.exclusiveOffers,
                        LandingAdsTab.newListing,
                        LandingAdsTab.openHouses,
                        LandingAdsTab.mostViewed,
                      ].firstWhere(
                        (tab) => tab.trLabel() == category,
                        orElse: () => LandingAdsTab.exclusiveOffers,
                      );

                      ref.read(selectedMobileLandingSectionTabProvider.notifier).state = mappedTab;
                      
                      final selectedIndex = allTabs.indexOf(category);
                      if (selectedIndex >= 2 && _currentTabPage == 0) {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else if (selectedIndex < 2 && _currentTabPage == 1) {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    tabs: currentTabs,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              tabPages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentTabPage == index 
                      ?  theme.themeColor
                      : Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Expanded(
            child: listingProvider.when(
              data: (adsList) {
                if (adsList.isEmpty) {
                  return Center(child: AppLottie.noResults(size: 200));
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListView.separated(
                    controller: _scrollController,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemCount: adsList.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final ad = adsList[index];
                      final tag = 'mobile-landing-${ad.id}-${UniqueKey().toString()}';

                      return SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: DragScrollView(
                          controller: _scrollController,
                          child: SelectedCardWidget(
                            isMobile: true,
                            aspectRatio: 3 / 3,
                            ad: ad,
                            tag: tag,
                            mainImageUrl: ad.images.isNotEmpty ? ad.images.last : '',
                            isPro: false,
                            isDefaultDarkSystem: MediaQuery.of(context).platformBrightness == Brightness.dark,
                            color: CustomColors.landingpagewidgetcolor(context, ref),
                            textColor: CustomColors.landingPageTextColor(context, ref),
                            textFieldColor: CustomColors.landingPageSubHeadingColor(context, ref),
                            buildShimmerPlaceholder: const ShimmerPlaceholder(
                              width: 400,
                              height: 300,
                            ),
                            buildPieMenuActions: buildPieMenuActions(ref, ad, context),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ShimmerLoadingRow(
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  placeholderwidget: const ShimmerPlaceholder(
                    width: 400,
                    height: 300,
                  ),
                ),
              ),
              error: (error, stackTrace) {
                final screenWidth = MediaQuery.of(context).size.width;
                final itemWidth = screenWidth - 32;
                final itemHeight = itemWidth * 0.75; 
                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: itemWidth,
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
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BuildPropertyCard extends ConsumerWidget {
  final String imageUrl;
  final String location;
  final String address;
  final String size;
  final String rooms;
  final String bath;
  final String price;

  const BuildPropertyCard({
    super.key,
    required this.imageUrl,
    required this.location,
    required this.address,
    required this.size,
    required this.rooms,
    required this.bath,
    required this.price,
  });

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 280,
      decoration: BoxDecoration(
        color: CustomColors.landingpagewidgetcolor(context, ref),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    color: CustomColors.landingPageSubHeadingColor(
                      context,
                      ref,
                    ),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    color: CustomColors.landingPageTextColor(context, ref),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    BuildIconText(icon: Icons.square_foot, text: size),
                    BuildIconText(icon: Icons.bed, text: rooms),
                    BuildIconText(icon: Icons.bathtub, text: bath),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(color: CustomColors.landingPageTextColor(context, ref)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FOR SALE'.tr,
                      style: TextStyle(
                        color: CustomColors.landingPageSubHeadingColor(
                          context,
                          ref,
                        ),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        color: CustomColors.landingPageTextColor(context, ref),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BuildIconText extends ConsumerWidget {
  final IconData icon;
  final String text;

  const BuildIconText({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context, ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: CustomColors.landingPageSubHeadingColor(context, ref),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: CustomColors.landingPageSubHeadingColor(context, ref),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}