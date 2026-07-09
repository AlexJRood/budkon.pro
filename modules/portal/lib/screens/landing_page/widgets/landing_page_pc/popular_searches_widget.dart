import 'dart:ui';

import 'package:core/shell/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:portal/screens/home_page/providers/listing_provider.dart';

import 'package:get/get_utils/get_utils.dart';

class PopularSearchesWidget extends ConsumerWidget {
  final double paddingDynamic;
  const PopularSearchesWidget({super.key, required this.paddingDynamic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewedAdsAsyncValue = ref.watch(listingsProvider);
    final dynamicVerticalPadding = paddingDynamic / 3;
    final scrollController = ScrollController();

    return Container(
        color: const Color.fromRGBO(255, 255, 255, 1),
      
        child:  Padding(
        padding: EdgeInsets.symmetric(vertical: dynamicVerticalPadding),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingDynamic),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'POPULAR SEARCHES'.tr,
                    style: AppTextStyles.libreCaslonHeading.copyWith(
                      color: const Color.fromRGBO(35, 35, 35, 1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color.fromRGBO(35, 35, 35, 1),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 24,
                        color: Color.fromRGBO(35, 35, 35, 1),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
     
              child: recentlyViewedAdsAsyncValue.when(
                data: (adsList) {
                  return ListView.separated(
                    controller: scrollController,
                      separatorBuilder: (context, index) => 
                            index==0 ? SizedBox() : const SizedBox(width: 10,),
                      itemCount: adsList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                    if (index == 0) {
                      // Pierwszy element listy - dynamiczny padding
                      return SizedBox(width: paddingDynamic);
                    }
                    final ad = adsList[index - 1]; // Przesuwamy indeksy, żeby zgadzały się z danymi
                    final tag = 'recentlyViewed4-${ad.id}-${UniqueKey().toString()}';

                        return DragScrollView(
                    controller: scrollController,
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
                                ref.read(navigationService).pushNamedScreen(
                                  '${Routes.entry}offer/${ad.id}',
                                  data: {'tag': tag, 'ad': ad},
                                );
                              }
                            },

                              actions: buildPieMenuActions(ref, adclientprovider, context),
                              child: SelectedCardWidget(
                                  isMobile: false,
                                  aspectRatio: 4 / 3,
                                  ad: ad,
                                  tag: tag,
                                  mainImageUrl: ad.images.isNotEmpty ? ad.images.last : '',
                                  isPro: false, // zmień na prawdziwe isPro jeśli masz
                                  isDefaultDarkSystem: MediaQuery.of(context).platformBrightness == Brightness.dark,
                                  color: CustomColors.landingpagewidgetcolor(context, ref),
                                  textColor: CustomColors.landingPageTextColor(context, ref),
                                  textFieldColor: CustomColors.landingPageSubHeadingColor(context, ref),
                                  buildShimmerPlaceholder: ShimmerPlaceholder(width: 400, height: 300),
                                  buildPieMenuActions: buildPieMenuActions(ref, ad, context),
                                ),
                          ),
                        );
                      },
                    
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    '${'error_loading_ads'.tr}: $error'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
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
      child: ShimmerAdvertisementGrid(
        crossAxisCount: crossAxisCount,
      ),
    );
  }
}
