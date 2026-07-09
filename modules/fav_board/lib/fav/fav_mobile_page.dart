//lib/Pages/feed/feed_pc.dart

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:core/common/install_popup.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class FavMobilePage extends ConsumerWidget {
  const FavMobilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      grid = 2;
    }
    final sideMenuKey = GlobalKey<SideMenuState>();

    const double maxWidth = 1920;
    const double minWidth = 480;
    // Ustawienie maksymalnego i minimalnego rozmiaru czcionki
    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 10;
    // Obliczenie odpowiedniego rozmiaru czcionki
    double dynamicPadding = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    // Ograniczenie rozmiaru czcionki do zdefiniowanych minimum i maksimum
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);
    // Oblicz proporcję szerokości

    return PopupListener(
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: AppModule.portal,
        isTopAppBarHoveroverUI: true,
        childMobile: Padding(
          padding: const EdgeInsets.all(5),
          child: GestureDetector(
            onPanUpdate: (details) {
              scrollController.jumpTo(
                scrollController.offset - details.delta.dy,
              );
            },
            child: ref.watch(favAdsProvider).when(
                                    data: (filteredAdvertisements) =>
                                        CustomScrollView(
                                      controller: scrollController,
                                          slivers: [
                                        const SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: 60,
                                          ),
                                        ),
                                        SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: grid,
                                            childAspectRatio: 1.0,
                                            mainAxisSpacing: 5.0,
                                            crossAxisSpacing: 5.0,
                                          ),
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final feedAd =
                                                  filteredAdvertisements[index];
                                              final keyTag =
                                                  'feedAdKey${feedAd.id}-${UniqueKey().toString()}';

                                              final mainImageUrl =
                                                  feedAd.images.isNotEmpty
                                                      ? feedAd.images[0]
                                                      : 'default_image_url';
                                              String formattedPrice = customFormat
                                                  .format(feedAd.price);

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
                                                        PointerDeviceKind.touch) {
                                                      handleDisplayedAction(ref,
                                                          feedAd.id, context);
                                                      ref
                                                          .read(navigationService)
                                                          .pushNamedReplacementScreen(
                                                        '${Routes.fav}/${feedAd.id}',
                                                        data: {
                                                          'tag': keyTag,
                                                          'ad': feedAd
                                                        },
                                                      );
                                                    }
                                                  },
                                                  actions: buildPieMenuActions(
                                                      ref, feedAd, context),
                                                  child: Hero(
                                                    tag: keyTag,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0),
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
                                                                      'Brak obrazu'
                                                                          .tr,
                                                                      style: const TextStyle(
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
                                                                    .black
                                                                    .withAlpha(102),
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
                                                                  Text(
                                                                    '$formattedPrice ${feedAd.currency}',
                                                                    style: AppTextStyles
                                                                        .interBold
                                                                        .copyWith(
                                                                      fontSize:
                                                                          14,
                                                                      shadows: [
                                                                        Shadow(
                                                                          offset: const Offset(
                                                                              5.0,
                                                                              5.0),
                                                                          blurRadius:
                                                                              10.0,
                                                                          color: Colors
                                                                              .black
                                                                              .withAlpha(255),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    feedAd.title,
                                                                    style: AppTextStyles
                                                                        .interSemiBold
                                                                        .copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      shadows: [
                                                                        Shadow(
                                                                          offset: const Offset(
                                                                              5.0,
                                                                              5.0),
                                                                          blurRadius:
                                                                              10.0,
                                                                          color: Colors
                                                                              .black
                                                                              .withAlpha(255),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '${feedAd.city}, ${feedAd.street}',
                                                                    style: AppTextStyles
                                                                        .interRegular
                                                                        .copyWith(
                                                                      fontSize:
                                                                          10,
                                                                      shadows: [
                                                                        Shadow(
                                                                          offset: const Offset(
                                                                              5.0,
                                                                              5.0),
                                                                          blurRadius:
                                                                              10.0,
                                                                          color: Colors
                                                                              .black
                                                                              .withAlpha(255),
                                                                        ),
                                                                      ],
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
                                              );
                                            },
                                            childCount:
                                                filteredAdvertisements.length,
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: 55,
                                          ),
                                        ),
                                      ],
                                    ),
                                    loading: () => const Center(
                                        child: CircularProgressIndicator()),
                                    error: (error, stack) => Center(
                                        child: Text('Wystąpił błąd: $error'.tr)),
                                  ),
          ),
        ),
      ),
    );
  }
}
