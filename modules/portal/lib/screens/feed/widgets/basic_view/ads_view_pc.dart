import 'package:flutter/foundation.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:portal/bars/feed_bar_vertical.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/cache_manager.dart';
import 'package:portal/feed/components/quick_filters/quick_filters_widget.dart';
import 'package:portal/feed/components/quick_filters/tablet_quick_filters.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:map/map_state.dart';
import 'package:portal/screens/filters/widgets/sort_feed.dart';
import 'package:portal/screens/landing_page/widgets/landing_page_pc/map_widget.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import '../../components/browselist/widget/pc.dart';
import '../../components/browselist/widget/tablet.dart';
import '../../components/cards/selected_card.dart';
import 'package:portal/screens/filter_landing_page/providers/filter_provider.dart';
import 'package:portal/pie_menu/feed.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:portal/screens/feed/components/browselist/utils/api.dart';
import 'package:portal/models/ad_list_view_model.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:portal/emma/anchors/anchors_portal.dart';

class AdsViewPage extends ConsumerStatefulWidget {
  const AdsViewPage({super.key});

  @override
  _AdsViewPageState createState() => _AdsViewPageState();
}

class _AdsViewPageState extends ConsumerState<AdsViewPage> {
  static const int _pageSize = 10;

  final PagingController<int, AdsListViewModel> _pagingController =
      PagingController(firstPageKey: 1);

  final ScrollController _scrollController = ScrollController();

  // ❗️DON'T create GlobalKey in build()
  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();
  final FocusNode _focusNode = FocusNode();

  // Subskrypcja zmian filtrów
  ProviderSubscription<dynamic>? _filterSub;
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);

    clearCacheIfTooBig(manager: CacheManagerFeedAdsPhotos.instance);

    // ▶️ Słuchaj zmian filterProvider – poprawnie, manualnie, z możliwością .close()
    _filterSub = ref.listenManual(filterProvider, (prev, next) {
      if (!mounted) return;
      _pagingController.refresh();
    });

    Future.microtask(() async {
      ref.invalidate(browseListProvider);
      if (ApiServices.isUserLoggedIn()) {
        final apiBrowseAds = ref
            .read(browseListProvider)
            .maybeWhen(
              data: (ads) => ads.map((a) => a.id).whereType<int>().toList(),
              orElse: () => <int>[],
            );
        await ref
            .read(browseListProvider.notifier)
            .syncOfflineAdsWithApi(apiBrowseAds, ref);
      } else {
        ref.read(browseListProvider.notifier).loadOfflineBrowseList();
      }
    });
  }

  Map<String, dynamic> _buildMapSelectionQuery() {
    final viewport = ref.read(mapViewportProvider);

    if (viewport.polygon.length < 3) {
      return {};
    }

    final polygon = viewport.polygon
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');

    return {
      if (viewport.bbox != null && viewport.bbox!.isNotEmpty)
        'bbox': viewport.bbox!,
      'polygon': polygon,
    };
  }

  String _polygonSignatureFromViewport(MapViewportState state) {
    if (state.polygon.length < 3) return '';

    return state.polygon
        .map(
          (p) =>
              '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}',
        )
        .join('|');
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final items = _pagingController.itemList;
    if (items == null || items.isEmpty) return KeyEventResult.ignored;

    final cardType = ref.read(selectedCardProvider);
    final grid = cardType.gridCount(context);
    final current = _focusedIndex ?? 0;
    int next = current;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      next = (current + 1).clamp(0, items.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      next = (current - 1).clamp(0, items.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      next = (current + grid).clamp(0, items.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      next = (current - grid).clamp(0, items.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_focusedIndex != null) _openFocusedAd(items[_focusedIndex!]);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }

    setState(() => _focusedIndex = next);
    _scrollToFocused(next, cardType);
    return KeyEventResult.handled;
  }

  void _openFocusedAd(AdsListViewModel ad) {
    final path = ref.read(navigationService).currentPath;
    final currentPath = path == '/' ? '' : path;
    final tag = 'basicviewpc_${ad.id}';
    handleDisplayedAction(ref, ad, context);
    ref.read(navigationService).openPopup(
      '$currentPath/offer/${ad.slug}',
      data: {'tag': tag, 'ad': ad},
    );
  }

  void _scrollToFocused(int index, CardType cardType) {
    if (!_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 65;
    const double minDynamicPadding = 5;
    double dynamicPadding =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);
    final adFiledSize = (screenWidth - (dynamicPadding * 2)) - 80;

    final grid = cardType.gridCount(context);
    final itemWidth = (adFiledSize - cardType.basePadding * (grid - 1)) / grid;
    final itemHeight = itemWidth / cardType.aspectRatio;
    final row = index ~/ grid;

    // top spacer(70) + toolbar row(60) = 130; map height ignored (collapsed by default)
    const toolbarHeight = 130.0;
    final targetTop = toolbarHeight + row * (itemHeight + cardType.basePadding);
    final targetBottom = targetTop + itemHeight;

    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;

    if (targetTop < currentOffset + 20) {
      _scrollController.animateTo(
        (targetTop - 20).clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else if (targetBottom > currentOffset + viewportHeight - 20) {
      _scrollController.animateTo(
        (targetBottom - viewportHeight + 20).clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
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
        _pagingController.appendPage(advertisements, pageKey + 1);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _filterSub?.close();
    _pagingController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardType = ref.watch(selectedCardProvider);
    final grid = cardType.gridCount(context);
    final cardRatio = cardType.aspectRatio;
    final paddingByCard = cardType.basePadding;

    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 65;
    const double minDynamicPadding = 5;

    double dynamicPadding =
        (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxDynamicPadding - minDynamicPadding) +
        minDynamicPadding;
    dynamicPadding = dynamicPadding.clamp(minDynamicPadding, maxDynamicPadding);

    final adFiledSize = (screenWidth - (dynamicPadding * 2)) - 80;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        behavior: HitTestBehavior.translucent,
        child: EmmaUiAnchorTarget(
          anchorKey: PortalEmmaAnchors.feedPcRoot.anchorKey,

          spec: PortalEmmaAnchors.feedPcRoot,
          runtimeMode: PortalEmmaAnchors.feedPcRoot.runtimeMode,
          tapMode: PortalEmmaAnchors.feedPcRoot.tapMode,
          child: BarManager(
      appModule: AppModule.portal,
      sideMenuKey: _sideMenuKey,
      isTopAppBarHoveroverUI: true,
      onHoverBar: OnHoverBar.agentCrm,

      // ------------------ DESKTOP ------------------
      childrenPc: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: EmmaUiAnchorTarget(
                  anchorKey: PortalEmmaAnchors.feedPcQuickFilters.anchorKey,

                  spec: PortalEmmaAnchors.feedPcQuickFilters,
                  runtimeMode: PortalEmmaAnchors.feedPcQuickFilters.runtimeMode,
                  tapMode: PortalEmmaAnchors.feedPcQuickFilters.tapMode,
                  child: const QuickFilterWidget(),
                ),
              ),
              Expanded(
                flex: 20,
                child: EmmaUiAnchorTarget(
                  anchorKey: PortalEmmaAnchors.feedPcAdList.anchorKey,

                  spec: PortalEmmaAnchors.feedPcAdList,
                  runtimeMode: PortalEmmaAnchors.feedPcAdList.runtimeMode,
                  tapMode: PortalEmmaAnchors.feedPcAdList.tapMode,
                  child: Padding(
                  padding: const EdgeInsets.only(right: 65.0, left: 65.0),
                  child: CustomScrollView(
                    // ↓ keep offscreen memory small
                    cacheExtent: 200,
                    controller: _scrollController,
                    key: const PageStorageKey('ads_view_scroll_pc'),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 70),
                      ),
                      SliverToBoxAdapter(
                        child: EmmaUiAnchorTarget(
                          anchorKey: PortalEmmaAnchors.feedPcMapWidget.anchorKey,

                          spec: PortalEmmaAnchors.feedPcMapWidget,
                          runtimeMode: PortalEmmaAnchors.feedPcMapWidget.runtimeMode,
                          tapMode: PortalEmmaAnchors.feedPcMapWidget.tapMode,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const MapWidget(haveAds: false),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 15),
                      ),
                      SliverToBoxAdapter(
                        child: EmmaUiAnchorTarget(
                          anchorKey: PortalEmmaAnchors.feedPcSortBar.anchorKey,

                          spec: PortalEmmaAnchors.feedPcSortBar,
                          runtimeMode: PortalEmmaAnchors.feedPcSortBar.runtimeMode,
                          tapMode: PortalEmmaAnchors.feedPcSortBar.tapMode,
                          child: const SizedBox(
                            height: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 210,
                                  height: 40,
                                  child: DropdownSortSelector(),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      child: MapFeedToggleSelector(
                                        currentView: FeedMapViewMode.feed,
                                        feedRoute: '/feed',
                                        mapRoute: '/mapview',
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    SizedBox(
                                      height: 40,
                                      child: CardTypeSelector(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      PagedSliverGrid<int, AdsListViewModel>(
                        pagingController: _pagingController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: grid,
                          childAspectRatio: cardRatio,
                          crossAxisSpacing: paddingByCard,
                          mainAxisSpacing: paddingByCard,
                        ),
                        builderDelegate:
                            PagedChildBuilderDelegate<AdsListViewModel>(
                          itemBuilder: (context, ad, index) {
                            return RepaintBoundary(
                              child: _AdTile(
                                key: ValueKey(ad.id),
                                ad: ad,
                                adFiledSize: adFiledSize,
                                isFocused: _focusedIndex == index,
                                onTap: () =>
                                    setState(() => _focusedIndex = index),
                              ),
                            );
                          },
                          firstPageProgressIndicatorBuilder: (_) =>
                              ShimmerPlaceholderWidget(
                            adFiledSize: adFiledSize,
                            crossAxisCount: grid,
                          ),
                          newPageProgressIndicatorBuilder: (_) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                height: 28,
                                width: 28,
                                child: AppLottie.loading(size: 450),
                              ),
                            ),
                          ),
                          noItemsFoundIndicatorBuilder: (_) => Center(
                            child: AppLottie.noResults(size: 450),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
                ),
              ),
              const BrowseListPcWidget(isWhiteSpaceNeeded: true),
            ],
          ),
        ),
      ],
      //tablet
      childrenTablet: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Filter sidebar ───────────────────────────────────────────
              SizedBox(
                width: (((screenWidth - 800) / 400) * 30 + 180).clamp(
                  180.0,
                  210.0,
                ),
                child: const TabletQuickFiltersWidget(),
              ),

              // ── Main content area ────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: CustomScrollView(
                    cacheExtent: 200,
                    controller: _scrollController,
                    key: const PageStorageKey('ads_view_scroll_tablet'),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 70),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(
                                height: 180,
                                child: MapWidget(haveAds: false),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                SizedBox(
                                  width: 230,
                                  height: 35,
                                  child: DropdownSortSelector(),
                                ),
                                SizedBox(height: 35, child: CardTypeSelector()),
                              ],
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      PagedSliverGrid<int, AdsListViewModel>(
                        pagingController: _pagingController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth < 1000 ? 1 : 2,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        builderDelegate:
                            PagedChildBuilderDelegate<AdsListViewModel>(
                              itemBuilder: (context, ad, index) {
                                return RepaintBoundary(
                                  child: _AdTile(
                                    key: ValueKey(ad.id),
                                    ad: ad,
                                    adFiledSize: adFiledSize,
                                  ),
                                );
                              },
                              firstPageProgressIndicatorBuilder:
                                  (_) => ShimmerPlaceholderWidget(
                                    adFiledSize: adFiledSize,
                                    crossAxisCount: 2,
                                  ),
                              noItemsFoundIndicatorBuilder:
                                  (_) => Center(
                                    child: AppLottie.noResults(size: 400),
                                  ),
                            ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),

              // ── Browse-list panel ────────────────────────────────────────
              const BrowseListTabletWidget(isWhiteSpaceNeeded: true),
            ],
          ),
        ),
      ],

      // ------------------ MOBILE ------------------
      verticalButtons: FeedBarVerticalMobile(ref: ref),
      childrenMobile: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
            child: CustomScrollView(
              cacheExtent: 200,
              controller: _scrollController,
              key: const PageStorageKey('ads_view_scroll_mobile'),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: TopAppBarSize.resolve(context)),
                ),
                PagedSliverGrid<int, AdsListViewModel>(
                  pagingController: _pagingController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid,
                    childAspectRatio: 1,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  builderDelegate: PagedChildBuilderDelegate<AdsListViewModel>(
                    itemBuilder: (context, ad, index) {
                      return RepaintBoundary(
                        child: _AdTile(
                          key: ValueKey(ad.id),
                          ad: ad,
                          adFiledSize: adFiledSize,
                        ),
                      );
                    },
                    firstPageProgressIndicatorBuilder:
                        (_) => ShimmerPlaceholderWidget(
                          adFiledSize: adFiledSize,
                          crossAxisCount: grid,
                        ),
                    newPageProgressIndicatorBuilder:
                        (_) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    noItemsFoundIndicatorBuilder:
                        (_) => Center(child: AppLottie.noResults(size: 450)),
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
    );
  }
}

class _AdTile extends ConsumerStatefulWidget {
  const _AdTile({
    super.key,
    required this.ad,
    required this.adFiledSize,
    this.isFocused = false,
    this.onTap,
  });

  final AdsListViewModel ad;
  final double adFiledSize;
  final bool isFocused;
  final VoidCallback? onTap;

  @override
  ConsumerState<_AdTile> createState() => _AdTileState();
}

class _AdTileState extends ConsumerState<_AdTile> {
  String? _url;

  // OPTIONAL: serve a smaller thumbnail to the browser (adapt to your CDN)
  String _thumb(String url) {
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}w=440&h=300&fit=crop';
  }

  @override
  void initState() {
    super.initState();
    final main = widget.ad.images.isNotEmpty ? widget.ad.images[0] : null;
    _url = main == null ? null : _thumb(main);
  }

  @override
  void dispose() {
    if (_url != null) {
      // Evict this tile's bitmap from Flutter's cache when it scrolls away
      NetworkImage(_url!).evict();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    final textFieldColor =
        themeMode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themeColors.themeTextColor;
    final color = Theme.of(context).primaryColor;

    final tag = 'basicviewpc_${widget.ad.id}';
    final mainImageUrl = _url ?? 'default_image_url';
    final isPro = widget.ad.isPro;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: widget.isFocused
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withAlpha(50),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              )
            : const BoxDecoration(),
        child: DndSender(
      useLongPress: true,
      payload: DndPayload(
        type: DndPayloadType.advertisement,
        id: '${widget.ad.id}',
        action: 'hover_advertisement',
        subActions: ['assign_advertisement', 'hover_advertisement'],
        data: {'adId': widget.ad.id, 'title': widget.ad.title},
      ),
      onDragStarted: () {
        debugPrint('🎯 Drag started: ad_${widget.ad.id} - Showing client bar');
        ref.read(showHoverAppBarProvider.notifier).state = true;
      },
      onDragCompleted: () {
        ref.read(showHoverAppBarProvider.notifier).state = false;
      },
      child: SelectedCardWidget(
        isFeed: false,
        isMobile: false,
        aspectRatio: ref.watch(selectedCardProvider).aspectRatio,
        ad: widget.ad,
        tag: tag,
        mainImageUrl: mainImageUrl,
        isPro: isPro,
        isDefaultDarkSystem: isDefaultDarkSystem,
        color: color,
        textColor: textColor,
        textFieldColor: textFieldColor,
        buildShimmerPlaceholder: SizedBox(
          height: widget.adFiledSize,
          width: widget.adFiledSize,
          child: const ShimmerPlaceholder(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        buildPieMenuActions: buildPieMenuActions(ref, widget.ad, context),
      ),
        ),
      ),
    );
  }
}

// ============= Shimmer wrapper (unchanged) =============

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
