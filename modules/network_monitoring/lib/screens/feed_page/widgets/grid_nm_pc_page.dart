import 'dart:async';

import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:network_monitoring/components/cards/selected_card.dart';
import 'package:network_monitoring/components/open_nm_ad.dart' show openAdUrl;
import 'package:network_monitoring/models/monitoring_ads_model.dart';
import 'package:network_monitoring/pie_menu/network_monitoring.dart';
import 'package:network_monitoring/providers/search_page/filters_provider.dart';
import 'package:portal/feed/components/view/slected_view_provider.dart';
import 'package:portal/screens/filters/widgets/sort_feed.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';

class GridNMPcPage extends ConsumerStatefulWidget {
  const GridNMPcPage({super.key});

  @override
  ConsumerState<GridNMPcPage> createState() => GridPcPageState();
}

class GridPcPageState extends ConsumerState<GridNMPcPage> {
  static const int _pageSize = 20;

  final PagingController<int, MonitoringAdsModel> _pagingController =
      PagingController(firstPageKey: 1);
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _refreshDebounce;
  ProviderSubscription<dynamic>? _filtersSub;
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);

    _filtersSub = ref.listenManual(
      networkMonitoringFilterProvider,
      (prev, next) {
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => _focusedIndex = null);
          _pagingController.refresh();
        });
      },
      fireImmediately: false,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final items = _pagingController.itemList;
    if (items == null || items.isEmpty) return KeyEventResult.ignored;

    final cardType = ref.read(selectedCardProviderNM);
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
      if (_focusedIndex != null) {
        final ad = items[_focusedIndex!];
        openAdUrl(context, ref, ad, null, null, 'networkAd_${ad.id}');
      }
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }

    setState(() => _focusedIndex = next);
    _scrollToFocused(next, cardType);
    return KeyEventResult.handled;
  }

  void _scrollToFocused(int index, CardTypeNM cardType) {
    if (!_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 15;
    final dynamicPadding = ((screenWidth - minWidth) /
                (maxWidth - minWidth) *
                (maxDynamicPadding - minDynamicPadding) +
            minDynamicPadding)
        .clamp(minDynamicPadding, maxDynamicPadding);
    final adFiledSize = (screenWidth - (dynamicPadding * 2)) - 80;

    final grid = cardType.gridCount(context);
    final itemWidth =
        (adFiledSize - cardType.basePadding * (grid - 1)) / grid;
    final itemHeight = itemWidth / cardType.aspectRatio;
    final row = index ~/ grid;

    // Toolbar: top(65) + Row(40) + bottom(15) = 120
    const toolbarHeight = 120.0;
    final targetTop =
        toolbarHeight + row * (itemHeight + cardType.basePadding);
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
          .read(networkMonitoringFilterProvider.notifier)
          .fetchAdvertisementsNM(pageKey, _pageSize);

      if (!mounted) return;

      if (advertisements.isEmpty) {
        _pagingController.appendLastPage(const <MonitoringAdsModel>[]);
        return;
      }

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
    _refreshDebounce?.cancel();
    _filtersSub?.close();
    _pagingController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardProvider = ref.watch(selectedCardProviderNM);
    final grid = cardProvider.gridCount(context);
    final theme = ref.watch(themeColorsProvider);
    final count = ref.watch(networkMonitoringTotalCountProvider);

    const double maxWidth = 1920;
    const double minWidth = 1080;
    const double maxDynamicPadding = 40;
    const double minDynamicPadding = 15;

    final dynamicPadding = ((screenWidth - minWidth) /
                (maxWidth - minWidth) *
                (maxDynamicPadding - minDynamicPadding) +
            minDynamicPadding)
        .clamp(minDynamicPadding, maxDynamicPadding);

    final adFiledSize = (screenWidth - (dynamicPadding * 2)) - 80;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        behavior: HitTestBehavior.translucent,
        child: EmmaUiAnchorTarget(
      // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcGridRoot
      anchorKey: 'network_monitoring.feed.pc.grid.root',
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 65.0),
              child: CustomScrollView(
                controller: _scrollController,
                cacheExtent: 200,
                slivers: [
                  SliverToBoxAdapter(
                    child: EmmaUiAnchorTarget(
                      // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcToolbar
                      anchorKey: 'network_monitoring.feed.pc.toolbar',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 65, bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcSortSelector
                              anchorKey:
                                  'network_monitoring.feed.pc.sort_selector',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                width: 210,
                                height: 40,
                                child: const DropdownSortSelector(
                                  isNetworkMonitoring: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcResultsCount
                              anchorKey:
                                  'network_monitoring.feed.pc.results_count',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.dashboardContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: 40,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "$count ${'ads found'.tr}",
                                      style: TextStyle(
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const EmmaUiAnchorTarget(
                              // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcMapToggle
                              anchorKey:
                                  'network_monitoring.feed.pc.map_toggle',
                              child: MapFeedToggleSelector(
                                currentView: FeedMapViewMode.feed,
                                feedRoute: '/network-monitoring',
                                mapRoute: '/network-monitoring/map',
                              ),
                            ),
                            const SizedBox(width: 10),
                            const SizedBox(
                              height: 40,
                              child: EmmaUiAnchorTarget(
                                // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcCardTypeSelector
                                anchorKey:
                                    'network_monitoring.feed.pc.card_type_selector',
                                child: CardTypeSelector(
                                  isNetworkMonitoring: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PagedSliverGrid<int, MonitoringAdsModel>(
                    pagingController: _pagingController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: grid,
                      childAspectRatio: cardProvider.aspectRatio,
                      crossAxisSpacing: cardProvider.basePadding,
                      mainAxisSpacing: cardProvider.basePadding,
                    ),
                    builderDelegate:
                        PagedChildBuilderDelegate<MonitoringAdsModel>(
                      itemBuilder: (context, ad, index) {
                        return RepaintBoundary(
                          child: AdGridItemNM(
                            key: ValueKey(ad.id),
                            ad: ad,
                            adFiledSize: adFiledSize,
                            isFocused: _focusedIndex == index,
                            onTap: () => setState(() => _focusedIndex = index),
                          ),
                        );
                      },
                      firstPageProgressIndicatorBuilder: (_) =>
                          ShimmerPlaceholderWidget(
                        adFiledSize: adFiledSize,
                        crossAxisCount: grid,
                      ),
                      newPageProgressIndicatorBuilder: (_) =>
                          ShimmerPlaceholderWidget(
                        adFiledSize: adFiledSize,
                        crossAxisCount: 1,
                      ),
                      noItemsFoundIndicatorBuilder: (_) => EmmaUiAnchorTarget(
                        // @emma-backend: NetworkMonitoringEmmaAnchors.feedPcNoResults
                        anchorKey: 'network_monitoring.feed.pc.no_results',
                        child: Center(child: AppLottie.noResults(size: 450)),
                      ),
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

class AdGridItemNM extends ConsumerWidget {
  const AdGridItemNM({
    super.key,
    required this.ad,
    required this.adFiledSize,
    this.isFocused = false,
    this.onTap,
  });

  final MonitoringAdsModel ad;
  final double adFiledSize;
  final bool isFocused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final currentThemeMode = ref.watch(themeProvider);
    final textFieldColor =
        currentThemeMode == ThemeMode.system ? Colors.black : Colors.white;
    final textColor = themeColors.themeTextColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);
    final cardProvider = ref.watch(selectedCardProviderNM);

    final tag = 'networkAd_${ad.id}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: isFocused
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
        child: EmmaUiAnchorTarget(
          // Runtime item anchor.
          anchorKey: 'network_monitoring.feed.pc.card.${ad.id}',
          child: DndSender(
            payload: DndPayload(
              action: 'add_to_favorites',
              type: DndPayloadType.nm_ad,
              id: ad.id.toString(),
              data: {
                'advertisement': ad.id,
                'advertisement_id': ad.id,
                'title': ad.title,
                'source': 'network_monitoring',
              },
            ),
            feedbackBuilder: (context) => DragFeedbackBuilders.nmAdFeedback(
              context,
              ad.title ?? 'property_ad'.tr,
            ),
            child: SelectedCardWidgetNM(
              isMobile: false,
              aspectRatio: cardProvider.aspectRatio,
              ad: ad,
              tag: tag,
              mainImageUrl: ad.mainImageUrl,
              isPro: ad.isPro,
              isDefaultDarkSystem: isDefaultDarkSystem,
              color: color,
              textColor: textColor,
              textFieldColor: textFieldColor,
              buildShimmerPlaceholder: ShimmerPlaceholderWidget(
                adFiledSize: adFiledSize,
                crossAxisCount: 1,
              ),
              buildPieMenuActions: buildPieMenuActionsNM(
                ref,
                ad,
                context,
                null,
                null,
              ),
            ),
          ),
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
      child: ShimmerAdvertisementGrid(crossAxisCount: crossAxisCount),
    );
  }
}