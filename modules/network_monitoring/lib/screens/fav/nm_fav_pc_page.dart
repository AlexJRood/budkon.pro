import 'dart:math' as math;
import 'dart:ui';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:portal/bars/top_app_bar_portal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:network_monitoring/screens/feed_pop/providers/fav/provider.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';

import 'package:core/platform/navigation_service.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';


class NMFavPcPage extends ConsumerWidget {
  const NMFavPcPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    final ScrollController scrollController = ScrollController();
    double screenWidth = MediaQuery.of(context).size.width;
    NumberFormat customFormat = NumberFormat.decimalPattern('fr');

    int grid;
    if (screenWidth >= 1440) {
      grid = math.max(1, (screenWidth / 500).ceil());
    } else if (screenWidth >= 1080) {
      grid = 3;
    } else if (screenWidth >= 600) {
      grid = 2;
    } else {
      grid = 1;
    }

    const double maxWidth = 1920;
    const double minWidth = 1080;

    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 15;

    double dynamicPadding = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);

    const double minBaseTextSize = 5;
    const double maxBaseTextSize = 15;
    double baseTextSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxBaseTextSize - minBaseTextSize) +
        minBaseTextSize;
    baseTextSize = baseTextSize.clamp(minBaseTextSize, maxBaseTextSize);

    return  BarManager(
          sideMenuKey: sideMenuKey,
          appModule: AppModule.networkMonitoring,
          layoutTypePc: LayoutTypePc.row,


          childrenPc: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    gradient: CustomBackgroundGradients.getMainMenuBackground(
                          context, ref)),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left: dynamicPadding, right: dynamicPadding),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            const SliverToBoxAdapter(
                              child: SizedBox(
                                  height: 70), // Przestrzeń dla TopAppBar
                            ),
                            ref.watch(nMFavAdsProvider).when(
                                  data: (filteredAdvertisements) {
                                    if (filteredAdvertisements.isEmpty) {
                                      return SliverToBoxAdapter(
                                        child: Column(children: [
                                          const Spacer(),
                                          Text(
                                              'oops_no_liked_ads'.tr,
                                              style:
                                                  AppTextStyles.interLight16),
                                          const Spacer(),
                                        ]),
                                      );
                                    }
                                    return SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: grid,
                                        childAspectRatio: 1.0,
                                        mainAxisSpacing: 1,
                                        crossAxisSpacing: 1,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final feedAd =
                                              filteredAdvertisements[index];
                                          final keyTag =
                                              'feedAdKey${feedAd.id}-${UniqueKey().toString()}';
                                          String formattedPrice =
                                              customFormat.format(feedAd.price);

                                          final mainImageUrl = feedAd.images?.isNotEmpty == true
                                              ? feedAd.images!.first
                                              : 'default_image_url';

                                          return AspectRatio(
                                            aspectRatio: 1,
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
                                                if (kind ==
                                                        PointerDeviceKind
                                                            .mouse ||
                                                    kind ==
                                                        PointerDeviceKind
                                                            .touch) {
                                                  handleDisplayedAction(
                                                      ref, feedAd.id, context);
                                             
                                             // TODO: finish flow
                                             
                                                }
                                              },
                                              actions: buildPieMenuActions(
                                                  ref, feedAd, context),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: Hero(
                                                  tag: keyTag,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Stack(
                                                      children: [
                                                        AspectRatio(
                                                          aspectRatio: 1,
                                                          child: FittedBox(
                                                            fit: BoxFit.cover,
                                                            child:
                                                                Image.network(
                                                              mainImageUrl,
                                                              errorBuilder:
                                                                  (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      Container(
                                                                color:
                                                                    Colors.grey,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                    'No picture'
                                                                        .tr,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white)),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          left: 2,
                                                          bottom: 2,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 5,
                                                                    bottom: 5,
                                                                    right: 8,
                                                                    left: 8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black.withAlpha((255 * 0.4).toInt()),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: Text(
                                                                    '$formattedPrice ${feedAd.currency}',
                                                                    style: AppTextStyles
                                                                        .interBold
                                                                        .copyWith(
                                                                            fontSize:
                                                                                18),
                                                                  ),
                                                                ),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: Text(
                                                                    feedAd.title ?? 'no_title'.tr,
                                                                    style: AppTextStyles
                                                                        .interSemiBold
                                                                        .copyWith(
                                                                            fontSize:
                                                                                14),
                                                                  ),
                                                                ),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: Text(
                                                                    '${feedAd.city}, ${feedAd.street}',
                                                                    style: AppTextStyles
                                                                        .interRegular
                                                                        .copyWith(
                                                                            fontSize:
                                                                                12),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount:
                                            filteredAdvertisements.length,
                                      ),
                                    );
                                  },
                                  loading: () => const SliverFillRemaining(
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  error: (error, stack) => SliverFillRemaining(
                                    child: Center(
                                      child: Text('${'An error occurred'.tr}: $error'.tr,
                                          style: AppTextStyles.interLight),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 4,
                                sigmaY: 4), // Adjust the blur intensity
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: CustomBackgroundGradients
                                    .backgroundGradientRight35(context, ref),
                              ), // Semi-transparent overlay to enhance the blur effect
                              child: const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: TopAppBarPortal(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
    );
  }
}
