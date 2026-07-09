import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/components/cards/va.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'dart:math' as math;

final realEstateSortByProvider = StateProvider<String>((ref) => 'desc');

class RealStateAndHomeForSaleGridView extends ConsumerWidget {
  final bool isMobile;
  const RealStateAndHomeForSaleGridView({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingProvider = ref.watch(networkMonitoringFilterProvider);
    final sortBy = ref.watch(realEstateSortByProvider);
    double screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.read(themeColorsProvider);

    int grid =
        (screenWidth >= 1440)
            ? math.max(1, (screenWidth / 500).ceil())
            : (screenWidth >= 1080)
            ? 3
            : (screenWidth >= 600)
            ? 2
            : 1;
    grid = grid < 1 ? 1 : grid;

    const double maxWidth = 1080;
    const double minWidth = 350;
    const double maxDynamicPadding = 15;
    const double minDynamicPadding = 5;
    double dynamicPadding = ((screenWidth - minWidth) /
                (maxWidth - minWidth) *
                (maxDynamicPadding - minDynamicPadding) +
            minDynamicPadding)
        .clamp(minDynamicPadding, maxDynamicPadding);

    final adFiledSize = screenWidth - (dynamicPadding * 2);

    int crossAxisCount;
    if (screenWidth < 700) {
      crossAxisCount = 1;
    } else if (screenWidth < 1028) {
      crossAxisCount = 2;
    } else if (screenWidth < 1415) {
      crossAxisCount = 3;
    } else if (screenWidth < 1745) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header with title and sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Estate & Homes For Sale'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '345 ${'Results'.tr}',
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.65).toInt()),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    Text(
                      'Sort by:'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.7).toInt()),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final newSort = sortBy == 'desc' ? 'asc' : 'desc';
                        ref.read(realEstateSortByProvider.notifier).state =
                            newSort;
                      },
                      child: Container(
                        height: 32,
                        width: 165,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.textColor.withAlpha(
                              (255 * 0.7).toInt(),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            sortBy == 'desc'
                                ? 'Price (Highest - Lowest)'.tr
                                : 'Price (Lowest - Highest)'.tr,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 20),

          /// Grid
          listingProvider.when(
            data: (data) {
              // Sort based on the price field
              final sortedData = [...data];
              sortedData.sort((a, b) {
                final aPrice = double.tryParse(a.price?.toString() ?? '') ?? 0;
                final bPrice = double.tryParse(b.price?.toString() ?? '') ?? 0;

                return sortBy == 'desc'
                    ? bPrice.compareTo(aPrice)
                    : aPrice.compareTo(bPrice);
              });

              return GridView.builder(
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                cacheExtent: 160,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedData.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return BuildAdvertisementsList(
                    adFiledSize: adFiledSize,
                    scrollController: ScrollController(),
                    buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                      adFiledSize: adFiledSize,
                      crossAxisCount: 1,
                    ),
                    networkMonitoringFilterProvider: [sortedData[index]],
                  );
                },
              );
            },
            loading:
                () => SizedBox(
                  height: 500,
                  child: ShimmerAdvertisementGrid(
                    crossAxisCount: crossAxisCount,
                    scrollPhysics: const NeverScrollableScrollPhysics(),
                  ),
                ),
            error:
                (error, stackTrace) => Center(
                  child: Text(
                    'Error'.tr + error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class BuildAdvertisementsList extends ConsumerWidget {
  final List<MonitoringAdsModel> networkMonitoringFilterProvider;
  final ScrollController scrollController;
  final Widget buildShimmerPlaceholder;
  final double adFiledSize;

  const BuildAdvertisementsList({
    super.key,
    required this.networkMonitoringFilterProvider,
    required this.scrollController,
    required this.buildShimmerPlaceholder,
    required this.adFiledSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themecolors = ref.watch(themeColorsProvider);
    final currentthememode = ref.watch(themeProvider);

    final textFieldColor =
        currentthememode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themecolors.themeTextColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    return Column(
      children: List.generate(networkMonitoringFilterProvider.length, (index) {
        final ad = networkMonitoringFilterProvider[index];
        final tag = 'networkAd${ad.id}-${UniqueKey().toString()}';
        final cardRatio = CardTypeNM.vanda.aspectRatio;

        final mainImageUrl =
            ad.images?.isNotEmpty == true
                ? ad.images!.first
                : 'default_image_url';
        final isPro = ad.isPro;

        return NetworMonitoringCardVandA(
          isMobile: false,
          aspectRatio: cardRatio,
          ad: ad,
          tag: tag,
          mainImageUrl: mainImageUrl,
          isPro: isPro,
          isDefaultDarkSystem: isDefaultDarkSystem,
          color: color,
          textColor: textColor,
          textFieldColor: textFieldColor,
          buildShimmerPlaceholder: buildShimmerPlaceholder,
          buildPieMenuActions: buildPieMenuActionsNM(
            ref,
            ad,
            context,
            null,
            null,
          ),
        );
      }),
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
