import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:portal/screens/home_page/providers/listing_provider.dart';
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';

import 'package:get/get_utils/get_utils.dart';

class GetHomeRecommendationsWidget extends ConsumerWidget {
  final double paddingDynamic;
  final bool isMobile;
  const GetHomeRecommendationsWidget({
    super.key,
    required this.paddingDynamic,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, ref) {
    final recentlyViewedAdsAsyncValue = ref.watch(listingsProvider);
    final theme = ref.read(themeColorsProvider);
    final dynamicVerticalPadding = paddingDynamic / 3;
    final screenSizeWidth = MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = max(150.0, min(screenWidth / 1500 * 240, 250.0));
    final itemHeight = itemWidth * (300 / 260);
    return Container(
      width: double.infinity,

      padding: EdgeInsets.only(
        left: paddingDynamic,
        right: paddingDynamic,
        top: dynamicVerticalPadding,
        bottom: dynamicVerticalPadding,
      ),
      child: isMobile
              ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildInfoSection(context, ref, isMobile,theme),

                  // Right Section (Cards)
                  recentlyViewedAdsAsyncValue.when(
                    data: (ads) {
                      return Container(
                        color: Colors.transparent,
                        height: 420,
                        width: screenSizeWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (
                              int i = 0;
                              i < ads.length && i < 2;
                              i++
                            ) // wyświetl maksymalnie 2 ogłoszenia
                              Positioned(
                                left: i == 0 ? 0.0 : screenSizeWidth/4 -40 , // przesunięcie kart
                                top: i == 1 ? 80.0 : 0.0,
                                child: Container(
                                  width: screenSizeWidth*3/4 ,
                                  height: (screenSizeWidth*3/4)*3/4,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.textFieldColor.withAlpha((255 * 0.5).toInt()),
                                        spreadRadius: 8,
                                        blurRadius: 8,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: SelectedCardWidget(
                                    isMobile: isMobile,
                                    aspectRatio:  4/3 ,
                                    ad: ads[i],
                                    tag: 'ad_tag_$i', // zmień na właściwy tag, jeśli masz
                                    mainImageUrl:
                                        ads[i].images.isNotEmpty
                                            ? ads[i].images.last
                                            : '',
                                    isPro: false,
                                    isDefaultDarkSystem:
                                        MediaQuery.of(
                                          context,
                                        ).platformBrightness ==
                                        Brightness.dark,
                                    color: theme.textFieldColor,
                                    textColor: theme.textColor,
                                    textFieldColor: theme.textFieldColor,
                                    buildShimmerPlaceholder: ShimmerPlaceholder(
                                            width: screenSizeWidth*3/4 ,
                                            height: (screenSizeWidth*3/4)*3/4,
                                    ),
                                    buildPieMenuActions: buildPieMenuActions(
                                      ref,
                                      ads[i],
                                      context,
                                    ),
                                  ),
                                ),
                              ),

                            // Twoje dodatkowe elementy (np. belki z ikonkami) zostaw bez zmian:
                            Positioned(
                              bottom: 40,
                              left: 0,
                              child: _buildRecommendationCard(),
                            ),
                            Positioned(
                              top: 120,
                              left: 20,
                              child: _buildStarReviews(),
                            ),
                            Positioned(
                              top: 50,
                              right: 0,
                              child: _buildHappyClientsCard(),
                            ),
                          ],
                        ),
                      );
                    },
                    loading:
                        () => Center(
                          child: CircularProgressIndicator(
                            color: CustomColors.landingPageTextColor(
                              context,
                              ref,
                            ),
                          ),
                        ),
                    error:
                        (error, stackTrace) => Center(
                          child: Text(
                            'Error loading data: $error'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  
                  _buildInfoSection(context, ref, isMobile,theme),
                  // Right Section (Cards)
                  recentlyViewedAdsAsyncValue.when(
                    data: (ads) {
                      return Container(
                        color: Colors.transparent,
                        height: 420,
                        width: 680,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (
                              int i = 0;
                              i < ads.length && i < 2;
                              i++
                            ) // wyświetl maksymalnie 2 ogłoszenia
                              Positioned(
                                left:
                                    i == 0 ? 80.0 : 250.0, // przesunięcie kart
                                top: i == 1 ? 50.0 : 0.0,
                                child: Container(
                                  width:  400,
                                  height:  300,
                                  decoration: BoxDecoration(                                   
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.textFieldColor.withAlpha((255 * 0.5).toInt()),
                                        spreadRadius: 8,
                                        blurRadius: 8,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: SelectedCardWidget(
                                    isMobile: isMobile,
                                    aspectRatio: 4 / 3,
                                    ad: ads[i],
                                    tag: 'ad_${ads[i].id}_recommendations',
                                    mainImageUrl: ads[i].images.isNotEmpty
                                            ? ads[i].images.last
                                            : '',
                                    isPro: false,
                                    isDefaultDarkSystem:
                                        MediaQuery.of(
                                          context,
                                        ).platformBrightness ==
                                        Brightness.dark,
                                    color: theme.textFieldColor,
                                    textColor: theme.textColor,
                                    textFieldColor: theme.textFieldColor,
                                    buildShimmerPlaceholder: ShimmerPlaceholder(
                                            width: screenSizeWidth*3/4 ,
                                            height: (screenSizeWidth*3/4)*3/4,
                                    ),
                                    buildPieMenuActions: buildPieMenuActions(
                                      ref,
                                      ads[i],
                                      context,
                                    ),
                                  ),
                                ),
                              ),

                            // Twoje dodatkowe elementy (np. belki z ikonkami) zostaw bez zmian:
                            Positioned(
                              bottom: 40,
                              left: 0,
                              child: _buildRecommendationCard(),
                            ),
                            Positioned(
                              top: 120,
                              left: 20,
                              child: _buildStarReviews(),
                            ),
                            Positioned(
                              top: 130,
                              right: 0,
                              child: _buildHappyClientsCard(),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Padding(
                      padding: EdgeInsets.only(left:paddingDynamic),
                      child: ShimmerLoadingRow(
                        shimmerItemsCount: 1,
                        itemWidth: itemWidth,
                        itemHeight: itemHeight,
                        placeholderwidget: ShimmerPlaceholder(
                          width: itemWidth,
                          height: itemHeight,
                        ),
                      ),
                    ),
                    error:
                        (error, stackTrace) => Center(
                          child: Text(
                            'Error loading data: $error'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoSection(BuildContext context,WidgetRef ref, isMobile,ThemeColors theme) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Text(
            'GET HOME RECOMMENDATIONS'.tr,
            style: AppTextStyles.libreCaslonHeading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join us to access personalized recommendations, exclusive listings,\nand more features tailored just for you.'.tr,
            style: TextStyle(
              fontSize: 16,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: isMobile ? const Size(300, 48) : const Size(142, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              backgroundColor: AppColors.redBeige,
              foregroundColor: CustomColors.landingPageButtonTextcolor(
                context,
                ref,
              ),
            ),
            onPressed: () => pushLoginNative(ref),
            child: Text(
              'Sign In'.tr,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
          isMobile ? const SizedBox(height: 30) : const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      height: 64,
      width: 247,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(233, 233, 233, 1),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 1),
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
            child: AppIcons.location(),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended homes'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(35, 35, 35, 1),
                ),
              ),
              Text(
                'Based on your budget'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color.fromRGBO(90, 90, 90, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarReviews() {
    return Container(
      height: 51,
      width: 130,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(233, 233, 233, 1),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Icon(Icons.star, color: Colors.yellow.shade800),
            ),
          ),
          const Text(
            '(238 reviews)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(35, 35, 35, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHappyClientsCard() {
    return Container(
      height: 58,
      width: 180,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(233, 233, 233, 1),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
     child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Container(
      height: 44,
      width: 44,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(35, 35, 35, 1),
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      child: const Center(
        child: Text(
          '10K+',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(255, 255, 255, 1),
          ),
        ),
      ),
    ),
    const SizedBox(width: 10),

    // 🔧 KLUCZ: owiń w Expanded/Flexible, a teksty przytnij
    Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Happy clients!'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(35, 35, 35, 1),
            ),
          ),
          Text(
            'Feedback received'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(90, 90, 90, 1),
            ),
          ),
        ],
      ),
    ),
  ],
),

    );
  }
}
