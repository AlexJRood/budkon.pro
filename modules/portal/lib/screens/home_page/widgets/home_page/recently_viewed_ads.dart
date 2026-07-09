import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:portal/screens/feed/components/cards/simple_card.dart';
import 'package:portal/widgets/landing_page_pc/components/category_buttons.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

import '../../../../enum/landing_ads_tab.dart';
import '../../../../global_providers/landing_page_ads_provider.dart';

final selectedRecentlyViewedCategoryProvider =
StateProvider<LandingAdsTab>((ref) => LandingAdsTab.recentlyViewed);

class RecentlyViewedAds extends ConsumerStatefulWidget {
  final double paddingDynamic;
  final bool isMobile;
  final bool isTablet;

  const RecentlyViewedAds({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  ConsumerState<RecentlyViewedAds> createState() => _RecentlyViewedAdsState();
}

class _RecentlyViewedAdsState extends ConsumerState<RecentlyViewedAds> {
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
    final selectedCategory = ref.watch(selectedRecentlyViewedCategoryProvider);
    final recentlyViewedAdsAsyncValue =
    ref.watch(landingPageAdsProvider(selectedCategory));

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    final baseTextSize = max(
      12.0,
      min((itemWidth - 150) / (240 - 150) * (16 - 12) + 12, 16.0),
    );
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.paddingDynamic / 6,
        top: widget.paddingDynamic / 15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.paddingDynamic,
                    right: widget.isMobile? widget.paddingDynamic * 1:widget.paddingDynamic * 3,
                  ),
                  child: CategorySelector(
                    isMobile: widget.isMobile,
                    isTablet: widget.isTablet,
                    selectedCategory: selectedCategory.trLabel(),
                    onCategorySelected: (newCategory) {
                      final selectedTab = [
                        LandingAdsTab.recentlyViewed,
                        LandingAdsTab.forYou,
                      ].firstWhere(
                            (tab) => tab.trLabel() == newCategory,
                        orElse: () => LandingAdsTab.recentlyViewed,
                      );

                      ref
                          .read(selectedRecentlyViewedCategoryProvider.notifier)
                          .state = selectedTab;
                    },
                    tabs: [
                      LandingAdsTab.recentlyViewed.trLabel(),
                      LandingAdsTab.forYou.trLabel(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: widget.isMobile? 4:widget.paddingDynamic),
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
                      icon: Icon(Icons.arrow_back, size: widget.isMobile? 16:24, color: theme.textColor),
                    ),
                    SizedBox(width: widget.isMobile? 6:20),
                    IconButton(
                      onPressed: () {
                        _scrollController.animateTo(
                          _scrollController.offset + 300,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      },
                      icon: Icon(Icons.arrow_forward, size: widget.isMobile? 16:24, color: theme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.only(right: widget.paddingDynamic),
            child: recentlyViewedAdsAsyncValue.when(
              data: (ads) {
                if (ads.isEmpty) {
                  return Center(child: AppLottie.noResults(size: 200));
                }

                return DragScrollView(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ads.asMap().entries.map((entry) {
                        return SimpleAdCard(
                          itemWidth: itemWidth,
                          itemHeight: itemHeight,
                          baseTextSize: baseTextSize,
                          paddingDynamic: widget.paddingDynamic,
                          index: entry.key,
                          displayedAd: entry.value,
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => Padding(
                padding: EdgeInsets.only(left: widget.paddingDynamic),
                child: ShimmerLoadingRow(
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  placeholderwidget: ShimmerPlaceholder(
                    width: itemWidth,
                    height: itemHeight,
                  ),
                ),
              ),
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
        ],
      ),
    );
  }
}