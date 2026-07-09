import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/components/cards/selected_card.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:portal/bars/feed_bar_vertical.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'dart:math' as math;
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';

import 'package:get/get_utils/get_utils.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';

class GridMobilePage extends ConsumerStatefulWidget {
  const GridMobilePage({super.key});

  @override
  _GridMobilePageState createState() => _GridMobilePageState();
}

class _GridMobilePageState extends ConsumerState<GridMobilePage> {
  static const int _pageSize = 10;
  final PagingController<int, AdsListViewModel> _pagingController =
      PagingController(firstPageKey: 1);

  // manual Riverpod subscription
  ProviderSubscription<dynamic>? _filterSub;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);

    // 🔒 przeniesiony nasłuch z build() do initState()
    _filterSub = ref.listenManual(
      filterProvider,
      (prev, next) {
        if (!mounted) return;
        _pagingController.refresh();
      },
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    try {
      final advertisements = await ref
          .read(filterProvider.notifier)
          .fetchAdvertisements(pageKey, _pageSize, ref);

      if (!mounted) return;

      final isLastPage = advertisements.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(advertisements);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(advertisements, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _filterSub?.close(); // ✅ zamknij subskrypcję
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ❌ NIE słuchamy tu: ref.listen(filterProvider, ...)

    double screenWidth = MediaQuery.of(context).size.width;
    final sideMenuKey = GlobalKey<SideMenuState>();

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

    const double maxWidth = 1080;
    const double minWidth = 350;
    const double maxDynamicPadding = 15;
    const double minDynamicPadding = 5;

    double dynamicPadding = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);

    final adFiledSize = (screenWidth - (dynamicPadding * 2));

    return EmmaUiAnchorTarget(
      anchorKey: PortalEmmaAnchors.feedMobileRoot.anchorKey,

      spec: PortalEmmaAnchors.feedMobileRoot,
      runtimeMode: PortalEmmaAnchors.feedMobileRoot.runtimeMode,
      tapMode: PortalEmmaAnchors.feedMobileRoot.tapMode,
      child: BarManager(
      appModule: AppModule.portal,
      sideMenuKey: sideMenuKey,
      isTopAppBarHoveroverUI: true,
      layoutTypeMobile: LayoutTypeMobile.column,
      enableScrool: false,

      verticalButtons: FeedBarVerticalMobile(ref: ref),

      childrenMobile: [
        SizedBox(
          height: TopAppBarSize.resolve(context) + 10,
        ),
        Expanded(
          child: EmmaUiAnchorTarget(
            anchorKey: PortalEmmaAnchors.feedMobileAdList.anchorKey,

            spec: PortalEmmaAnchors.feedMobileAdList,
            runtimeMode: PortalEmmaAnchors.feedMobileAdList.runtimeMode,
            tapMode: PortalEmmaAnchors.feedMobileAdList.tapMode,
            child: PagedGridView<int, AdsListViewModel>(
            pagingController: _pagingController,
            padding: EdgeInsets.symmetric(
              horizontal: dynamicPadding,
              vertical: 65,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: grid,
              childAspectRatio: 1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
              itemBuilder: (context, advertisement, index) {
                return BuildAdvertisementsList(
                  adFiledSize: adFiledSize,
                  buildShimmerPlaceholder: const ShimmerPlaceholder(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  filteredAdvertisements: [advertisement],
                );
              },
              firstPageProgressIndicatorBuilder: (_) => ShimmerPlaceholderWidget(
                adFiledSize: adFiledSize,
                crossAxisCount: grid,
              ),
              newPageProgressIndicatorBuilder: (_) => AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      const ShimmerPlaceholder(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: Container(
                          width: 300,
                          height: 75,
                          padding: const EdgeInsets.only(top: 15, left: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((255 * 0.4).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerPlaceholder(width: 100, height: 12),
                              SizedBox(height: 10),
                              ShimmerPlaceholder(width: 280, height: 10),
                              SizedBox(height: 8),
                              ShimmerPlaceholder(width: 120, height: 7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Text(
                  'no_search_results'.tr,
                  style: AppTextStyles.interLight16,
                ),
              ),
            ),
          ),
          ),
        ),
        SizedBox(
          height: TopAppBarSize.withTopAppBar(context),
        ),
      ],
      ),
    );
  }
}

class BuildAdvertisementsList extends ConsumerWidget {
  final List<AdsListViewModel> filteredAdvertisements;
  final Widget buildShimmerPlaceholder;
  final double adFiledSize;

  const BuildAdvertisementsList({
    super.key,
    required this.filteredAdvertisements,
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
      children: List.generate(filteredAdvertisements.length, (index) {
        final ad = filteredAdvertisements[index];
        final tag = 'mobileSize${ad.id}-${UniqueKey().toString()}';
        final mainImageUrl =
            ad.images.isNotEmpty ? ad.images[0] : 'default_image_url';
        final isPro = ad.isPro;

        return SelectedCardWidget(
          isMobile: false,
          aspectRatio: 1,
          ad: ad,
          tag: tag,
          mainImageUrl: mainImageUrl,
          isPro: isPro,
          isDefaultDarkSystem: isDefaultDarkSystem,
          color: color,
          textColor: textColor,
          textFieldColor: textFieldColor,
          buildShimmerPlaceholder: buildShimmerPlaceholder,
          buildPieMenuActions: buildPieMenuActions(ref, ad, context),
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
      child: const ShimmerAdvertisementGrid(),
    );
  }
}
