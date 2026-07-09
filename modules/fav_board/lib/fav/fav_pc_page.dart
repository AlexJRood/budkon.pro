import 'dart:math' as math;
import 'dart:ui';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/platform/route_constant.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:intl/intl.dart';
import 'package:pie_menu/pie_menu.dart';

class FavPcPage extends ConsumerStatefulWidget {
  const FavPcPage({super.key});

  @override
  ConsumerState<FavPcPage> createState() => _FavPcPageState();
}

class _FavPcPageState extends ConsumerState<FavPcPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarHoveroverUI: true,
      childPc: _FavPcContent(scrollController: _scrollController),
    );
  }
}

class _FavPcContent extends ConsumerWidget {
  final ScrollController scrollController;

  const _FavPcContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 70),
          ),
          ref.watch(favAdsProvider).when(
                data: (filteredAdvertisements) {
                  if (filteredAdvertisements.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Column(children: [
                        const Spacer(),
                        Text(
                          'Upss... brak polubionych ogłoszeń.'.tr,
                          style: AppTextStyles.interLight16,
                        ),
                        const Spacer(),
                      ]),
                    );
                  }
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: grid,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final feedAd = filteredAdvertisements[index];
                        final keyTag =
                            'feedAdKey${feedAd.id}-${UniqueKey().toString()}';
                        final formattedPrice =
                            customFormat.format(feedAd.price);
                        final mainImageUrl = feedAd.images.isNotEmpty
                            ? feedAd.images[0]
                            : 'default_image_url';

                        return FavoriteAdCardWidget(
                          feedAd: feedAd,
                          keyTag: keyTag,
                          mainImageUrl: mainImageUrl,
                          formattedPrice: formattedPrice,
                          handleDisplayedAction: handleDisplayedAction,
                        );
                      },
                      childCount: filteredAdvertisements.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Wystąpił błąd: $error'.tr,
                      style: AppTextStyles.interLight,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class FavoriteAdCardWidget extends ConsumerWidget {
  final dynamic feedAd;
  final String keyTag;
  final String mainImageUrl;
  final String formattedPrice;
  final void Function(WidgetRef ref, int id, BuildContext context)
      handleDisplayedAction;

  const FavoriteAdCardWidget({
    super.key,
    required this.feedAd,
    required this.keyTag,
    required this.mainImageUrl,
    required this.formattedPrice,
    required this.handleDisplayedAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1,
      child: PieMenu(
        theme: PieTheme.of(context).copyWith(
          overlayColor: (() {
            final theme = ref.watch(themeColorsProvider);
            final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
            final base = uiIsDark ? Colors.black : Colors.white;
            return base.withValues(alpha: 0.70);
          })(),
        ),
        onPressedWithDevice: (kind) {
          if (kind == PointerDeviceKind.mouse ||
              kind == PointerDeviceKind.touch) {
            handleDisplayedAction(ref, feedAd.id, context);
            ref.read(navigationService).pushNamedScreen(
              '${Routes.fav}/${feedAd.id}',
              data: {'tag': keyTag, 'ad': feedAd},
            );
          }
        },
        actions: buildPieMenuActions(ref, feedAd, context),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Hero(
            tag: keyTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Image.network(
                        mainImageUrl,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey,
                          alignment: Alignment.center,
                          child: Text(
                            'Brak obrazu'.tr,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(102),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '$formattedPrice ${feedAd.currency}',
                              style: AppTextStyles.interBold
                                  .copyWith(fontSize: 18),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              feedAd.title,
                              style: AppTextStyles.interSemiBold
                                  .copyWith(fontSize: 14),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '${feedAd.city}, ${feedAd.street}',
                              style: AppTextStyles.interRegular
                                  .copyWith(fontSize: 12),
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
  }
}
